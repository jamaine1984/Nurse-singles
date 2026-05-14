const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const crypto = require("crypto");
const {GoogleAuth} = require("google-auth-library");
const {
  entitlementPlans,
  usagePlanFeatures,
  videoMinuteProducts,
  productRevenueCents,
  planFromRevenueCatSubscriber,
  isRevenueCatEntitlementActive,
} = require("./subscription_config");

admin.initializeApp();

const revenueCatApiKey = defineSecret("REVENUECAT_API_KEY");
const visionAuth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/cloud-platform"],
});

const subscriptionProductIdsByPlan = {
  "tech": "tech_monthly",
  "college": "college_monthly",
  "nurse": "nurse_monthly",
  "doctor": "doctor_monthly",
};

const videoAdMinuteMilestones = {
  10: 1,
  50: 7,
  200: 35,
};

const maxDailyVideoAdRewards = 200;
const maxDailyBoostAdCredits = 4;
const maxDailyUsageAdRefills = 5;
const maxUsageRefillAmount = 3;
const boostDurationMinutes = 30;
const maxVoiceMessageSeconds = 15;
const defaultPartnerGivebackRateBps = 1000;
const cleanupBatchSize = 450;
const staleSpeedRoomMinutes = 20;
const staleActiveRoomMinutes = 45;
const completedVideoRetentionDays = 30;
const notificationRetentionDays = 14;
const expiredBoostRetentionDays = 7;
const orphanedMediaRetentionDays = 30;
const allowedImageCategories = new Set(["profile", "gallery", "post", "chat"]);
const safeSearchRanks = {
  "UNKNOWN": 0,
  "VERY_UNLIKELY": 1,
  "UNLIKELY": 2,
  "POSSIBLE": 3,
  "LIKELY": 4,
  "VERY_LIKELY": 5,
};

/**
 * Moderates a pending user image before moving it to a public app path.
 */
exports.moderateUploadedImage = onCall({
  timeoutSeconds: 60,
  memory: "512MiB",
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to upload photos.");
  }

  const userId = request.auth.uid;
  const storagePath = requireString(request.data.storagePath, "storagePath");
  const destinationPath = requireString(
      request.data.destinationPath,
      "destinationPath",
  );
  const category = requireString(request.data.category, "category");
  const contentType = optionalString(request.data.contentType) || "image/jpeg";

  if (!allowedImageCategories.has(category)) {
    throw new HttpsError("invalid-argument", "Unsupported image category.");
  }
  if (!contentType.startsWith("image/")) {
    throw new HttpsError("invalid-argument", "Only image uploads are allowed.");
  }
  validateModeratedImagePaths({
    userId,
    category,
    storagePath,
    destinationPath,
  });

  const bucket = admin.storage().bucket();
  const pendingFile = bucket.file(storagePath);
  const [exists] = await pendingFile.exists();
  if (!exists) {
    throw new HttpsError("not-found", "Pending upload was not found.");
  }

  const [metadata] = await pendingFile.getMetadata();
  const uploadedBy = metadata.metadata && metadata.metadata.uploadedBy;
  if (uploadedBy !== userId) {
    await pendingFile.delete({ignoreNotFound: true});
    throw new HttpsError("permission-denied", "Upload owner mismatch.");
  }
  const size = Number(metadata.size || 0);
  if (size <= 0 || size > 10 * 1024 * 1024) {
    await pendingFile.delete({ignoreNotFound: true});
    throw new HttpsError("invalid-argument", "Image must be under 10 MB.");
  }

  let safety;
  try {
    const [bytes] = await pendingFile.download();
    safety = await analyzeImageSafety(bytes);
  } catch (error) {
    console.error("Image moderation failed:", error);
    throw new HttpsError(
        "unavailable",
        "Image safety check is temporarily unavailable. Please try again.",
    );
  }

  const blocked = isUnsafeImage(safety);
  await logImageModeration({
    userId,
    category,
    storagePath,
    destinationPath,
    safety,
    status: blocked ? "rejected" : "approved",
  });

  if (blocked) {
    await pendingFile.delete({ignoreNotFound: true});
    throw new HttpsError(
        "failed-precondition",
        "This photo cannot be uploaded. Please choose a clothed, safe image.",
    );
  }

  const token = crypto.randomUUID();
  const destinationFile = bucket.file(destinationPath);
  await pendingFile.copy(destinationFile, {
    metadata: {
      contentType,
      metadata: {
        uploadedBy: userId,
        moderatedBy: "google-safe-search",
        moderationStatus: "approved",
        originalPendingPath: storagePath,
        firebaseStorageDownloadTokens: token,
      },
    },
  });
  await pendingFile.delete({ignoreNotFound: true});

  return {
    approved: true,
    downloadUrl: firebaseDownloadUrl(bucket.name, destinationPath, token),
    storagePath: destinationPath,
  };
});

/**
 * Send push notification when a new match is created
 * Triggered automatically when a document is created in the 'matches' collection
 */
exports.sendMatchNotification = onDocumentCreated("matches/{matchId}", async (event) => {
  const matchData = event.data.data();
  const matchId = event.params.matchId;

  console.log(`New match created: ${matchId}`);
  console.log("Match data:", matchData);

  try {
    const users = Array.isArray(matchData.users) ? matchData.users : [];
    const user1Id = matchData.user1Id || matchData.user1 || users[0];
    const user2Id = matchData.user2Id || matchData.user2 || users[1];

    if (!user1Id || !user2Id) {
      console.error("Match notification skipped: missing participant IDs");
      return null;
    }

    // Get both users' data
    const [user1Doc, user2Doc] = await Promise.all([
      admin.firestore().collection("users").doc(user1Id).get(),
      admin.firestore().collection("users").doc(user2Id).get(),
    ]);

    if (!user1Doc.exists || !user2Doc.exists) {
      console.error("One or both users not found");
      return null;
    }

    const user1Data = user1Doc.data();
    const user2Data = user2Doc.data();

    // Send notification to user1 about matching with user2
    if (user1Data.fcmToken) {
      await sendNotificationToUser(
          user1Data.fcmToken,
          "New Match!",
          `You matched with ${user2Data.name}! Start chatting now.`,
          {
            type: "new_match",
            matchId: matchId,
            userId: user2Id,
            userName: user2Data.name,
          },
      );
      console.log(`Notification sent to user1: ${user1Data.name}`);
    }

    // Send notification to user2 about matching with user1
    if (user2Data.fcmToken) {
      await sendNotificationToUser(
          user2Data.fcmToken,
          "New Match!",
          `You matched with ${user1Data.name}! Start chatting now.`,
          {
            type: "new_match",
            matchId: matchId,
            userId: user1Id,
            userName: user1Data.name,
          },
      );
      console.log(`Notification sent to user2: ${user2Data.name}`);
    }

    return null;
  } catch (error) {
    console.error("Error sending match notification:", error);
    return null;
  }
});

/**
 * Send push notification when a new like is received
 * Triggered automatically when a document is created in the 'likes' collection
 */
exports.sendLikeNotification = onDocumentCreated("likes/{likeId}", async (event) => {
  const likeData = event.data.data();
  const likeId = event.params.likeId;

  console.log(`New like created: ${likeId}`);

  try {
    // Don't send notification if it's already a match
    if (likeData.isMatched) {
      console.log("Skipping like notification - already matched");
      return null;
    }

    const likerId = likeData.likerId;
    const likedUserId = likeData.likedUserId;
    const likeType = likeData.likeType || "like";

    // Get liker's data
    const likerDoc = await admin.firestore().collection("users").doc(likerId).get();

    if (!likerDoc.exists) {
      console.error("Liker not found");
      return null;
    }

    const likerData = likerDoc.data();

    // Get liked user's data
    const likedUserDoc = await admin.firestore().collection("users").doc(likedUserId).get();

    if (!likedUserDoc.exists) {
      console.error("Liked user not found");
      return null;
    }

    const likedUserData = likedUserDoc.data();

    // Send notification to liked user
    if (likedUserData.fcmToken) {
      const title = likeType === "superlike" ? "New Superlike!" : "Someone Likes You!";
      const body = `${likerData.name} ${likeType === "superlike" ? "superliked" : "liked"} you!`;

      await sendNotificationToUser(
          likedUserData.fcmToken,
          title,
          body,
          {
            type: "new_like",
            likeType: likeType,
            userId: likerId,
            userName: likerData.name,
          },
      );

      console.log(`Like notification sent to: ${likedUserData.name}`);
    }

    return null;
  } catch (error) {
    console.error("Error sending like notification:", error);
    return null;
  }
});

/**
 * Send push notification when a new message is sent
 * Triggered automatically when a document is created in any 'messages' subcollection
 */
exports.sendMessageNotification = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const messageData = event.data.data();
  const chatId = event.params.chatId;

  console.log(`New message in chat: ${chatId}`);

  try {
    const senderId = messageData.senderId;
    const messageContent = messageData.content;

    // Get chat document to find the recipient
    const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();

    if (!chatDoc.exists) {
      console.error("Chat not found");
      return null;
    }

    const chatData = chatDoc.data();
    const participants = chatData.participants || [];

    // Find recipient (the participant who is not the sender)
    const recipientId = participants.find((id) => id !== senderId);

    if (!recipientId) {
      console.error("Recipient not found");
      return null;
    }

    // Get sender and recipient data
    const [senderDoc, recipientDoc] = await Promise.all([
      admin.firestore().collection("users").doc(senderId).get(),
      admin.firestore().collection("users").doc(recipientId).get(),
    ]);

    if (!senderDoc.exists || !recipientDoc.exists) {
      console.error("Sender or recipient not found");
      return null;
    }

    const senderData = senderDoc.data();
    const recipientData = recipientDoc.data();

    // Send notification to recipient
    if (recipientData.fcmToken) {
      // Truncate message if too long
      let displayContent = messageContent;
      if (displayContent.length > 100) {
        displayContent = displayContent.substring(0, 97) + "...";
      }

      await sendNotificationToUser(
          recipientData.fcmToken,
          `${senderData.name}`,
          displayContent,
          {
            type: "new_message",
            chatId: chatId,
            senderId: senderId,
            senderName: senderData.name,
          },
      );

      console.log(`Message notification sent to: ${recipientData.name}`);
    }

    return null;
  } catch (error) {
    console.error("Error sending message notification:", error);
    return null;
  }
});

/**
 * Callable function to send a test notification
 * Can be called from the app for testing purposes
 */
exports.sendTestNotification = onCall(async (request) => {
  const userId = request.auth?.uid;

  if (!userId) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  try {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User not found");
    }

    const userData = userDoc.data();

    if (!userData.fcmToken) {
      throw new HttpsError("failed-precondition", "User has no FCM token");
    }

    await sendNotificationToUser(
        userData.fcmToken,
        "Test Notification",
        "Push notifications are working correctly!",
        {
          type: "test",
          timestamp: Date.now().toString(),
        },
    );

    console.log(`Test notification sent to: ${userData.name}`);

    return {success: true, message: "Test notification sent successfully"};
  } catch (error) {
    console.error("Error sending test notification:", error);
    throw new HttpsError("internal", error.message);
  }
});

exports.completeZegoCallSession = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const sessionId = requireString(request.data?.sessionId, "sessionId");
      const durationSeconds = Math.max(
          0,
          Number(request.data?.durationSeconds) || 0,
      );
      const minutesUsed = Math.ceil(durationSeconds / 60);
      const db = admin.firestore();
      const sessionRef = db.collection("video_sessions").doc(sessionId);
      const userRef = db.collection("users").doc(userId);
      const usageRef = userRef.collection("usage").doc(`monthly_${monthKey()}`);

      await db.runTransaction(async (transaction) => {
        const [sessionSnap, userSnap] = await Promise.all([
          transaction.get(sessionRef),
          transaction.get(userRef),
        ]);
        if (!sessionSnap.exists) {
          throw new HttpsError("not-found", "Video session not found");
        }

        const session = sessionSnap.data();
        if (!Array.isArray(session.participants) ||
            !session.participants.includes(userId)) {
          throw new HttpsError(
              "permission-denied",
              "User is not a participant in this video session",
          );
        }

        const currentMinutes = Number(userSnap.data()?.videoMinutes || 0);
        const remainingMinutes = Math.max(0, currentMinutes - minutesUsed);
        transaction.update(sessionRef, {
          status: "completed",
          durationSeconds,
          minutesUsed,
          endedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.update(userRef, {
          "videoMinutes": remainingMinutes,
          "stats.videoMinutesUsed":
            admin.firestore.FieldValue.increment(minutesUsed),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.set(usageRef, {
          "videoMinutesUsed":
            admin.firestore.FieldValue.increment(minutesUsed),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      });

      await recordCostMetric(db, {
        feature: "video_call",
        userId,
        amount: minutesUsed,
        unit: "minutes",
        metadata: {sessionId},
      });

      return {success: true, minutesUsed};
    },
);

exports.syncRevenueCatCustomer = onCall(
    {secrets: [revenueCatApiKey], enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const subscriber = await fetchRevenueCatSubscriber(userId);
      const plan = planFromRevenueCatSubscriber(subscriber);
      const purchases = revenueCatMinutePurchases(userId, subscriber);
      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      let syncResult = {
        creditedVideoMinutes: 0,
        creditedPlanVideoMinutes: 0,
        creditedPurchaseIds: [],
      };

      await db.runTransaction(async (transaction) => {
        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }
        const userData = userSnap.data() || {};

        const creditRefs = purchases.map((purchase) => ({
          purchase,
          ref: db.collection("purchase_credits").doc(purchase.creditId),
        }));
        const creditSnaps = await Promise.all(
            creditRefs.map(({ref}) => transaction.get(ref)),
        );

        let creditedVideoMinutes = 0;
        const creditedPurchaseIds = [];
        creditSnaps.forEach((snap, index) => {
          if (snap.exists) return;
          const purchase = creditRefs[index].purchase;
          creditedVideoMinutes += purchase.minutes;
          creditedPurchaseIds.push(purchase.creditId);
        });

        const planMinuteAllowance =
          Number(planUsageLimits(plan).monthlyVideoMinutes || 0);
        const planCreditRef = planMinuteAllowance > 0 ?
          db.collection("subscription_minute_credits")
              .doc(`${userId}_${plan}_${monthKey()}`) :
          null;
        const planCreditSnap = planCreditRef ?
          await transaction.get(planCreditRef) :
          null;
        const creditedPlanVideoMinutes =
          planCreditRef && !planCreditSnap.exists ? planMinuteAllowance : 0;

        const partnerCode = normalizePartnerCode(userData.partnerCode);
        const partnerRevenueEvents = partnerCode ?
          revenueCatPartnerRevenueEvents({
            userId,
            subscriber,
            plan,
            purchases: creditRefs
                .filter((_, index) => !creditSnaps[index].exists)
                .map(({purchase}) => purchase),
          }) :
          [];
        const partnerRef = partnerCode ?
          db.collection("partner_organizations").doc(partnerCode) :
          null;
        const partnerSnap = partnerRef && partnerRevenueEvents.length > 0 ?
          await transaction.get(partnerRef) :
          null;
        const ledgerRefs = partnerRevenueEvents.map((event) => ({
          event,
          ref: db.collection("partner_giveback_ledger")
              .doc(partnerRevenueLedgerId(userId, partnerCode, event.eventId)),
        }));
        const ledgerSnaps = await Promise.all(
            ledgerRefs.map(({ref}) => transaction.get(ref)),
        );

        const updates = {
          "plan": plan,
          "revenueCat.lastSyncedAt":
            admin.firestore.FieldValue.serverTimestamp(),
          "revenueCat.lastSyncedPlan": plan,
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        };

        const totalCreditedVideoMinutes =
          creditedVideoMinutes + creditedPlanVideoMinutes;

        if (totalCreditedVideoMinutes > 0) {
          updates.videoMinutes =
            admin.firestore.FieldValue.increment(totalCreditedVideoMinutes);
          const usageRef = userRef.collection("usage")
              .doc(`monthly_${monthKey()}`);
          const usageUpdates = {
            "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
          };
          if (creditedVideoMinutes > 0) {
            usageUpdates.videoPurchased =
              admin.firestore.FieldValue.increment(creditedVideoMinutes);
          }
          if (creditedPlanVideoMinutes > 0) {
            usageUpdates.videoPlanGranted =
              admin.firestore.FieldValue.increment(creditedPlanVideoMinutes);
          }
          transaction.set(usageRef, usageUpdates, {merge: true});
        }

        transaction.set(userRef, updates, {merge: true});

        creditRefs.forEach(({purchase, ref}, index) => {
          if (creditSnaps[index].exists) return;
          transaction.set(ref, {
            userId,
            productId: purchase.productId,
            purchaseId: purchase.purchaseId,
            minutes: purchase.minutes,
            creditedAt: admin.firestore.FieldValue.serverTimestamp(),
            source: "revenuecat",
          });
        });

        if (planCreditRef && creditedPlanVideoMinutes > 0) {
          transaction.set(planCreditRef, {
            userId,
            plan,
            month: monthKey(),
            minutes: creditedPlanVideoMinutes,
            creditedAt: admin.firestore.FieldValue.serverTimestamp(),
            source: "revenuecat_plan_allowance",
          });
        }

        if (partnerSnap?.exists) {
          const partner = partnerSnap.data() || {};
          if (partner.status === "active") {
            recordPartnerRevenueEvents({
              transaction,
              partnerRef,
              partner,
              ledgerRefs,
              ledgerSnaps,
              partnerCode,
              userId,
            });
          }
        }

        syncResult = {
          creditedVideoMinutes,
          creditedPlanVideoMinutes,
          creditedPurchaseIds,
        };
      });

      const latestUser = await userRef.get();
      return {
        success: true,
        plan,
        creditedVideoMinutes: syncResult.creditedVideoMinutes,
        creditedPlanVideoMinutes: syncResult.creditedPlanVideoMinutes,
        creditedPurchaseIds: syncResult.creditedPurchaseIds,
        newVideoMinutes: Number(latestUser.data()?.videoMinutes || 0),
      };
    },
);

exports.claimVideoMinuteReward = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      assertClientUserMatchesAuth(request.data?.userId, userId);
      const rewardType = optionalString(request.data?.rewardType) || "ad";
      if (rewardType !== "ad") {
        throw new HttpsError("invalid-argument", "Unsupported reward type");
      }

      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      const dailyRef = userRef.collection("usage").doc(`daily_${dateKey()}`);
      let minutesGranted = 0;
      let adsWatchedToday = 0;

      await db.runTransaction(async (transaction) => {
        const [userSnap, dailySnap] = await Promise.all([
          transaction.get(userRef),
          transaction.get(dailyRef),
        ]);
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        const dailyData = dailySnap.data() || {};
        const claimed = Number(dailyData.videoAdRewardsClaimed || 0);
        if (claimed >= maxDailyVideoAdRewards) {
          throw new HttpsError(
              "resource-exhausted",
              "Daily ad reward limit reached",
          );
        }

        adsWatchedToday = claimed + 1;
        minutesGranted = Number(videoAdMinuteMilestones[adsWatchedToday] || 0);
        const userUpdates = {
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        };
        const dailyUpdates = {
          "videoAdRewardsClaimed":
            admin.firestore.FieldValue.increment(1),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        };

        if (minutesGranted > 0) {
          userUpdates.videoMinutes =
            admin.firestore.FieldValue.increment(minutesGranted);
          dailyUpdates.videoRewardMinutes =
            admin.firestore.FieldValue.increment(minutesGranted);
        }

        transaction.update(userRef, userUpdates);
        transaction.set(dailyRef, dailyUpdates, {merge: true});
      });

      return {
        success: true,
        rewardType,
        minutesGranted,
        adsWatchedToday,
        nextMilestone: nextVideoAdMilestone(adsWatchedToday),
      };
    },
);

exports.recordUsageEvent = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      assertClientUserMatchesAuth(request.data?.userId, userId);
      const eventType = requireString(request.data?.eventType, "eventType");
      const targetUserId = optionalString(request.data?.targetUserId);
      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);

      let remaining = -1;
      await db.runTransaction(async (transaction) => {
        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        const userData = userSnap.data() || {};
        const config = usageEventConfig(eventType, userData.plan);
        const usageRef = userRef.collection("usage").doc(config.docId());
        const usageSnap = await transaction.get(usageRef);
        const usageData = usageSnap.data() || {};
        const state = usageLimitState(userData, usageData, config);
        remaining = assertUsageAvailable(state, config, eventType);
        const targetRef = targetUserId ?
          db.collection("users").doc(targetUserId) :
          null;
        incrementUsage(transaction, userRef, usageRef, config, targetRef);
      });

      return {success: true, eventType, remaining};
    },
);

exports.recordSwipeWithLimit = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const targetUserId = requireString(request.data?.targetUserId, "targetUserId");
      if (targetUserId === userId) {
        throw new HttpsError("invalid-argument", "Cannot swipe on yourself");
      }

      const isSuperLike = request.data?.isSuperLike === true;
      const isLike = request.data?.isLike === true || isSuperLike;
      const eventType = isSuperLike ? "superlike" : isLike ? "like" : null;
      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      const targetRef = db.collection("users").doc(targetUserId);
      const sortedUsers = [userId, targetUserId].sort();
      const swipeRef = db.collection("swipes").doc(`${userId}_${targetUserId}`);
      const likeRef = db.collection("likes").doc(`${userId}_${targetUserId}`);
      const mutualLikeRef = db.collection("likes").doc(`${targetUserId}_${userId}`);
      const matchRef = db.collection("matches").doc(`${sortedUsers[0]}_${sortedUsers[1]}`);

      let result = {
        success: true,
        isMatch: false,
        duplicate: false,
        remaining: -1,
        usageType: eventType,
      };

      await db.runTransaction(async (transaction) => {
        const reads = [
          transaction.get(userRef),
          transaction.get(targetRef),
          transaction.get(swipeRef),
          transaction.get(likeRef),
          transaction.get(mutualLikeRef),
          transaction.get(matchRef),
        ];

        const [
          userSnap,
          targetSnap,
          existingSwipeSnap,
          existingLikeSnap,
          mutualLikeSnap,
          existingMatchSnap,
        ] = await Promise.all(reads);

        if (!userSnap.exists || !targetSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        const userData = userSnap.data() || {};
        const targetData = targetSnap.data() || {};
        if (isBlockedBetween(userData, targetData, userId, targetUserId)) {
          throw new HttpsError("failed-precondition", "This profile is unavailable");
        }

        const canCreateLike = isLike && !existingLikeSnap.exists;
        const isDuplicateSwipe = existingSwipeSnap.exists && !canCreateLike;
        if ((isLike && existingLikeSnap.exists) || isDuplicateSwipe) {
          result = {...result, duplicate: true};
          return;
        }

        if (eventType) {
          const config = usageEventConfig(eventType, userData.plan);
          const usageRef = userRef.collection("usage").doc(config.docId());
          const usageSnap = await transaction.get(usageRef);
          const state = usageLimitState(userData, usageSnap.data() || {}, config);
          result.remaining = assertUsageAvailable(state, config, eventType);
          result.usageType = config.usageType;
          incrementUsage(transaction, userRef, usageRef, config, targetRef);
        }

        const swipePayload = {
          "swiperId": userId,
          "swipedUserId": targetUserId,
          "isLike": isLike,
          "isSuperLike": isSuperLike,
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        };
        if (!existingSwipeSnap.exists) {
          swipePayload.createdAt = admin.firestore.FieldValue.serverTimestamp();
        }

        transaction.set(swipeRef, swipePayload, {merge: true});

        if (!isLike) return;

        transaction.set(likeRef, {
          "likerId": userId,
          "likedUserId": targetUserId,
          "likeType": isSuperLike ? "superlike" : "like",
          "isMatched": mutualLikeSnap.exists,
          "createdAt": admin.firestore.FieldValue.serverTimestamp(),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        });

        if (!mutualLikeSnap.exists || mutualLikeSnap.data()?.isMatched === true ||
            existingMatchSnap.exists) {
          return;
        }

        transaction.update(mutualLikeRef, {"isMatched": true});
        transaction.set(matchRef, {
          "users": sortedUsers,
          "user1": sortedUsers[0],
          "user2": sortedUsers[1],
          "user1Name": sortedUsers[0] === userId ?
            publicUserName(userData) :
            publicUserName(targetData),
          "user2Name": sortedUsers[1] === userId ?
            publicUserName(userData) :
            publicUserName(targetData),
          "user1Photo": sortedUsers[0] === userId ?
            publicUserPhoto(userData) :
            publicUserPhoto(targetData),
          "user2Photo": sortedUsers[1] === userId ?
            publicUserPhoto(userData) :
            publicUserPhoto(targetData),
          "createdAt": admin.firestore.FieldValue.serverTimestamp(),
          "lastInteraction": admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.set(userRef, {
          "stats.matches": admin.firestore.FieldValue.increment(1),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        transaction.set(targetRef, {
          "stats.matches": admin.firestore.FieldValue.increment(1),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        result = {...result, isMatch: true};
      });

      if (!result.duplicate) {
        await recordCostMetric(db, {
          feature: "swipe",
          userId,
          amount: 1,
          unit: "swipe",
          metadata: {
            targetUserId,
            type: isSuperLike ? "superlike" : isLike ? "like" : "pass",
          },
        });
      }

      return result;
    },
);

exports.sendChatMessage = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const chatId = requireString(request.data?.chatId, "chatId");
      const content = requireString(request.data?.content, "content");
      const type = optionalString(request.data?.type) || "text";
      const allowedTypes = ["text", "image", "gift", "videoCall", "voiceNote"];
      if (!allowedTypes.includes(type)) {
        throw new HttpsError("invalid-argument", "Unsupported message type");
      }
      if (type === "voiceNote") {
        assertVoiceNoteDurationAllowed(content);
      }

      const countsTowardMessageLimit = ["text", "image", "gift", "voiceNote"].includes(type);
      const config = countsTowardMessageLimit ? usageEventConfig("message") : null;
      const db = admin.firestore();
      const chatRef = db.collection("chats").doc(chatId);
      const userRef = db.collection("users").doc(userId);
      const usageRef = config ? userRef.collection("usage").doc(config.docId()) : null;
      const messageRef = chatRef.collection("messages").doc();
      let remaining = -1;

      await db.runTransaction(async (transaction) => {
        const [chatSnap, userSnap, usageSnap] = await Promise.all([
          transaction.get(chatRef),
          transaction.get(userRef),
          usageRef ? transaction.get(usageRef) : Promise.resolve(null),
        ]);
        if (!chatSnap.exists) {
          throw new HttpsError("not-found", "Chat not found");
        }
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        const chat = chatSnap.data() || {};
        const participants = Array.isArray(chat.participants) ? chat.participants : [];
        if (!participants.includes(userId)) {
          throw new HttpsError("permission-denied", "User is not in this chat");
        }

        const otherIds = participants.filter((id) => id !== userId);
        const otherRefs = otherIds.map((id) => db.collection("users").doc(id));
        const otherSnaps = await Promise.all(otherRefs.map((ref) => transaction.get(ref)));
        const userData = userSnap.data() || {};
        otherSnaps.forEach((snap, index) => {
          if (!snap.exists) return;
          if (isBlockedBetween(userData, snap.data() || {}, userId, otherIds[index])) {
            throw new HttpsError("failed-precondition", "Messaging is unavailable for this conversation");
          }
        });

        if (config && usageRef) {
          const state = usageLimitState(userData, usageSnap?.data() || {}, config);
          remaining = assertUsageAvailable(state, config, "message");
          incrementUsage(transaction, userRef, usageRef, config, null);
        }

        const preview = chatMessagePreview(type, content, request.data?.giftName);
        const unreadUpdates = {};
        otherIds.forEach((otherId) => {
          unreadUpdates[`unreadCount.${otherId}`] = admin.firestore.FieldValue.increment(1);
        });

        transaction.set(messageRef, {
          "chatId": chatId,
          "senderId": userId,
          "senderName": publicUserName(userData),
          "senderPhotoUrl": publicUserPhoto(userData),
          "content": content,
          "type": type,
          "giftId": optionalString(request.data?.giftId),
          "giftName": optionalString(request.data?.giftName),
          "giftEmoji": optionalString(request.data?.giftEmoji),
          "isRead": false,
          "createdAt": admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.set(chatRef, {
          "lastMessage": preview,
          "lastMessageTime": admin.firestore.FieldValue.serverTimestamp(),
          "lastMessageSenderId": userId,
          ...unreadUpdates,
        }, {merge: true});
      });

      await recordCostMetric(db, {
        feature: "chat_message",
        userId,
        amount: 1,
        unit: "message",
        metadata: {chatId, type},
      });

      return {
        success: true,
        chatId,
        messageId: messageRef.id,
        remaining,
      };
    },
);

exports.claimUsageRefill = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      assertClientUserMatchesAuth(request.data?.userId, userId);
      const usageType = requireString(request.data?.usageType, "usageType");
      const amount = Number(request.data?.amount || 0);
      const config = usageRefillConfig(usageType);
      if (!Number.isInteger(amount) ||
          amount < 1 ||
          amount > maxUsageRefillAmount) {
        throw new HttpsError(
            "invalid-argument",
            `Refill amount must be between 1 and ${maxUsageRefillAmount}`,
        );
      }

      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      const usageRef = userRef.collection("usage").doc(`daily_${dateKey()}`);
      let totalRefilled = 0;

      await db.runTransaction(async (transaction) => {
        const [userSnap, usageSnap] = await Promise.all([
          transaction.get(userRef),
          transaction.get(usageRef),
        ]);
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        const usageData = usageSnap.data() || {};
        const claims = Number(usageData[config.claimsField] || 0);
        if (claims >= maxDailyUsageAdRefills) {
          throw new HttpsError(
              "resource-exhausted",
              "Daily ad refill limit reached",
          );
        }

        totalRefilled = Number(usageData[config.refillField] || 0) + amount;
        transaction.set(usageRef, {
          [config.refillField]: admin.firestore.FieldValue.increment(amount),
          [config.claimsField]: admin.firestore.FieldValue.increment(1),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      });

      return {success: true, usageType, amount, totalRefilled};
    },
);

exports.blockUser = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      assertClientUserMatchesAuth(request.data?.userId, userId);
      const blockedUserId = requireString(
          request.data?.blockedUserId,
          "blockedUserId",
      );
      if (blockedUserId === userId) {
        throw new HttpsError("invalid-argument", "Cannot block yourself");
      }

      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      const blockedUserRef = db.collection("users").doc(blockedUserId);
      const sortedUsers = [userId, blockedUserId].sort();
      const matchRef = db.collection("matches")
          .doc(`${sortedUsers[0]}_${sortedUsers[1]}`);
      const likeRefs = [
        db.collection("likes").doc(`${userId}_${blockedUserId}`),
        db.collection("likes").doc(`${blockedUserId}_${userId}`),
      ];
      const swipeRefs = [
        db.collection("swipes").doc(`${userId}_${blockedUserId}`),
        db.collection("swipes").doc(`${blockedUserId}_${userId}`),
      ];

      await db.runTransaction(async (transaction) => {
        const [userSnap, blockedUserSnap] = await Promise.all([
          transaction.get(userRef),
          transaction.get(blockedUserRef),
        ]);
        if (!userSnap.exists || !blockedUserSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        transaction.set(userRef, {
          "blocked": admin.firestore.FieldValue.arrayUnion(blockedUserId),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        transaction.delete(matchRef);
        for (const ref of [...likeRefs, ...swipeRefs]) {
          transaction.delete(ref);
        }
      });

      const deletedChats = await deletePairChats(db, userId, blockedUserId);
      return {success: true, blockedUserId, deletedChats};
    },
);

exports.unblockUser = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      assertClientUserMatchesAuth(request.data?.userId, userId);
      const blockedUserId = requireString(
          request.data?.blockedUserId,
          "blockedUserId",
      );

      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      await userRef.set({
        "blocked": admin.firestore.FieldValue.arrayRemove(blockedUserId),
        "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      return {success: true, blockedUserId};
    },
);

exports.joinSpeedDatingRoom = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const roomId = requireString(request.data?.roomId, "roomId");
      const db = admin.firestore();
      const roomRef = db.collection("speed_dating_rooms").doc(roomId);
      const userRef = db.collection("users").doc(userId);
      let joinedParticipants = [];

      await db.runTransaction(async (transaction) => {
        const [roomSnap, userSnap] = await Promise.all([
          transaction.get(roomRef),
          transaction.get(userRef),
        ]);
        if (!roomSnap.exists) {
          throw new HttpsError("not-found", "Speed dating room not found");
        }
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        let room = roomSnap.data() || {};
        if (speedRoomShouldReset(room)) {
          room = {
            ...room,
            ...speedRoomClearedFields(userId),
          };
        } else if (room.status === "active") {
          throw new HttpsError(
              "failed-precondition",
              "This room is already in a video call",
          );
        }

        const participants = speedRoomParticipants(room);
        if (participants.includes(userId)) {
          joinedParticipants = participants;
          return;
        }
        if (participants.length >= 2) {
          throw new HttpsError("resource-exhausted", "This room is full");
        }

        const user = userSnap.data() || {};
        const update = {
          "status": "waiting",
          "maxParticipants": 2,
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
          "lastJoinedAt": admin.firestore.FieldValue.serverTimestamp(),
        };
        const slot = speedRoomFirstOpenSlot(room);
        update[`${slot}Id`] = userId;
        update[`${slot}Name`] = String(user.name || "Nurse");
        update[`${slot}PhotoUrl`] = user.photoUrl || null;
        update[`${slot}Age`] = user.age || null;

        joinedParticipants = [...participants, userId];
        update.currentParticipants = joinedParticipants;
        transaction.set(roomRef, update, {merge: true});
      });

      return {
        success: true,
        roomId,
        participants: joinedParticipants,
      };
    },
);

exports.leaveSpeedDatingRoom = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const roomId = requireString(request.data?.roomId, "roomId");
      const db = admin.firestore();
      const roomRef = db.collection("speed_dating_rooms").doc(roomId);
      let cleared = false;

      await db.runTransaction(async (transaction) => {
        const roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) return;

        const room = roomSnap.data() || {};
        const participants = speedRoomParticipants(room);
        if (!participants.includes(userId)) return;

        if (room.status === "active" || speedRoomShouldReset(room)) {
          transaction.set(roomRef, speedRoomClearedFields(userId), {
            merge: true,
          });
          cleared = true;
          return;
        }

        const remaining = participants.filter((id) => id !== userId);
        const update = {
          "currentParticipants": remaining,
          "status": "waiting",
          "startedAt": null,
          "lastLeftAt": admin.firestore.FieldValue.serverTimestamp(),
          "lastLeftBy": userId,
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        };

        for (const slot of ["user1", "user2"]) {
          if (room[`${slot}Id`] === userId) {
            update[`${slot}Id`] = null;
            update[`${slot}Name`] = null;
            update[`${slot}PhotoUrl`] = null;
            update[`${slot}Age`] = null;
          }
        }

        transaction.set(roomRef, update, {merge: true});
      });

      return {success: true, roomId, cleared};
    },
);

exports.activateSpeedDatingRoom = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const roomId = requireString(request.data?.roomId, "roomId");
      const db = admin.firestore();
      const roomRef = db.collection("speed_dating_rooms").doc(roomId);
      let participants = [];
      let activeSessionId = "";

      await db.runTransaction(async (transaction) => {
        const roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) {
          throw new HttpsError("not-found", "Speed dating room not found");
        }

        const room = roomSnap.data() || {};
        if (speedRoomShouldReset(room)) {
          transaction.set(roomRef, speedRoomClearedFields(userId), {
            merge: true,
          });
          throw new HttpsError(
              "failed-precondition",
              "This room was reset. Please join again.",
          );
        }

        participants = speedRoomParticipants(room);
        if (!participants.includes(userId)) {
          throw new HttpsError(
              "permission-denied",
              "User is not in this speed dating room",
          );
        }
        if (participants.length < 2) {
          throw new HttpsError(
              "failed-precondition",
              "Waiting for a second person",
          );
        }

        activeSessionId = optionalString(room.activeSessionId) ||
          `speed_${roomId}_${Date.now()}_${crypto.randomUUID()}`;
        const followUpRef = db.collection("speed_date_followups").doc(activeSessionId);
        transaction.set(roomRef, {
          "status": "active",
          "currentParticipants": participants,
          "activeSessionId": activeSessionId,
          "startedAt": admin.firestore.FieldValue.serverTimestamp(),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        transaction.set(followUpRef, {
          "roomId": roomId,
          "participants": participants,
          "responses": {},
          "status": "pending",
          "chatId": null,
          "createdAt": admin.firestore.FieldValue.serverTimestamp(),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      });

      return {success: true, roomId, participants, activeSessionId};
    },
);

exports.submitSpeedDateFollowUp = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const sessionId = requireString(request.data?.sessionId, "sessionId");
      const roomId = requireString(request.data?.roomId, "roomId");
      const otherUserId = requireString(request.data?.otherUserId, "otherUserId");
      if (otherUserId === userId) {
        throw new HttpsError("invalid-argument", "Other user is required");
      }
      const wantsToConnect = request.data?.wantsToConnect === true;
      const db = admin.firestore();
      const followUpRef = db.collection("speed_date_followups").doc(sessionId);
      const currentUserRef = db.collection("users").doc(userId);
      const otherUserRef = db.collection("users").doc(otherUserId);
      let response = {status: "pending", chatId: null};

      await db.runTransaction(async (transaction) => {
        const [
          followUpSnap,
          currentUserSnap,
          otherUserSnap,
          existingChatSnap,
        ] = await Promise.all([
          transaction.get(followUpRef),
          transaction.get(currentUserRef),
          transaction.get(otherUserRef),
          transaction.get(
              db.collection("chats")
                  .where("participants", "array-contains", userId),
          ),
        ]);
        if (!followUpSnap.exists) {
          throw new HttpsError("not-found", "Speed date follow-up not found");
        }
        if (!currentUserSnap.exists || !otherUserSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        const followUp = followUpSnap.data() || {};
        const participants = Array.isArray(followUp.participants) ?
          followUp.participants :
          [];
        if (followUp.roomId !== roomId ||
            !participants.includes(userId) ||
            !participants.includes(otherUserId)) {
          throw new HttpsError("permission-denied", "User is not in this speed date");
        }

        const currentUser = currentUserSnap.data() || {};
        const otherUser = otherUserSnap.data() || {};
        if (isBlockedBetween(currentUser, otherUser, userId, otherUserId)) {
          throw new HttpsError("failed-precondition", "This profile is unavailable");
        }

        if (followUp.status === "connected" && optionalString(followUp.chatId)) {
          response = {status: "connected", chatId: followUp.chatId};
          return;
        }
        if (followUp.status === "declined") {
          response = {status: "declined", chatId: null};
          return;
        }

        const responses = followUp.responses || {};
        const nextResponses = {
          ...responses,
          [userId]: wantsToConnect,
        };
        const otherResponse = nextResponses[otherUserId];
        let status = "pending";
        let chatRef = null;

        if (wantsToConnect === false || otherResponse === false) {
          status = "declined";
        } else if (wantsToConnect === true && otherResponse === true) {
          status = "connected";
          let existingChatId = null;
          existingChatSnap.docs.forEach((doc) => {
            const chat = doc.data() || {};
            const chatParticipants = Array.isArray(chat.participants) ? chat.participants : [];
            if (chatParticipants.length === 2 && chatParticipants.includes(otherUserId)) {
              existingChatId = doc.id;
            }
          });
          chatRef = existingChatId ?
            db.collection("chats").doc(existingChatId) :
            db.collection("chats").doc();

          if (!existingChatId) {
            transaction.set(chatRef, {
              "participants": [userId, otherUserId],
              "participantMap": {
                [userId]: true,
                [otherUserId]: true,
              },
              "participantNames": {
                [userId]: publicUserName(currentUser),
                [otherUserId]: publicUserName(otherUser),
              },
              "participantPhotos": {
                [userId]: publicUserPhoto(currentUser),
                [otherUserId]: publicUserPhoto(otherUser),
              },
              "lastMessage": "Speed date connection confirmed.",
              "lastMessageTime": admin.firestore.FieldValue.serverTimestamp(),
              "lastMessageSenderId": "system",
              "unreadCount": {[userId]: 0, [otherUserId]: 0},
              "createdAt": admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          const messageRef = chatRef.collection("messages").doc();
          transaction.set(messageRef, {
            "chatId": chatRef.id,
            "senderId": "system",
            "senderName": "Nurse Singles",
            "senderPhotoUrl": null,
            "content": "Speed date connection confirmed. Both of you chose " +
              "to reconnect. You can send a Shift Report or start chatting.",
            "type": "system",
            "giftId": null,
            "giftName": null,
            "giftEmoji": null,
            "isRead": false,
            "createdAt": admin.firestore.FieldValue.serverTimestamp(),
          });
          transaction.set(chatRef, {
            "lastMessage": "Speed date connection confirmed.",
            "lastMessageTime": admin.firestore.FieldValue.serverTimestamp(),
            "lastMessageSenderId": "system",
          }, {merge: true});
        }

        transaction.set(followUpRef, {
          "responses": nextResponses,
          [`respondedAt.${userId}`]: admin.firestore.FieldValue.serverTimestamp(),
          "status": status,
          "chatId": chatRef?.id || followUp.chatId || null,
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        response = {status, chatId: chatRef?.id || followUp.chatId || null};
      });

      return response;
    },
);

exports.recordBoostAdCredit = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      assertClientUserMatchesAuth(request.data?.userId, userId);
      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      const dailyRef = userRef.collection("usage").doc(`daily_${dateKey()}`);
      let boostAdCredits = 0;

      await db.runTransaction(async (transaction) => {
        const [userSnap, dailySnap] = await Promise.all([
          transaction.get(userRef),
          transaction.get(dailyRef),
        ]);
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        const userData = userSnap.data() || {};
        const dailyData = dailySnap.data() || {};
        const claimed = Number(dailyData.boostAdCreditsEarned || 0);
        if (claimed >= maxDailyBoostAdCredits) {
          throw new HttpsError(
              "resource-exhausted",
              "Daily boost ad limit reached",
          );
        }

        const currentCredits = Math.max(
            0,
            Number(userData.boostAdCredits || 0),
        );
        boostAdCredits = Math.min(2, currentCredits + 1);

        transaction.update(userRef, {
          "boostAdCredits": boostAdCredits,
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        });
        transaction.set(dailyRef, {
          "boostAdCreditsEarned":
            admin.firestore.FieldValue.increment(1),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      });

      return {
        success: true,
        boostAdCredits,
      };
    },
);

exports.activateProfileBoost = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      assertClientUserMatchesAuth(request.data?.userId, userId);
      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      const expiresAt = new Date(Date.now() + boostDurationMinutes * 60000);
      let boostAdCredits = 0;
      let boostSource = "rewarded_ads";

      await db.runTransaction(async (transaction) => {
        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }

        const userData = userSnap.data() || {};
        const plan = String(userData.plan || "free");
        const hasPlanBoost = plan === "nurse" || plan === "doctor";
        const updates = {
          "isBoosted": true,
          "boostExpiresAt":
            admin.firestore.Timestamp.fromDate(expiresAt),
          "lastBoostActivatedAt":
            admin.firestore.FieldValue.serverTimestamp(),
          "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
        };

        if (hasPlanBoost) {
          boostSource = "plan";
          boostAdCredits = Math.max(
              0,
              Number(userData.boostAdCredits || 0),
          );
        } else {
          const currentCredits = Math.max(
              0,
              Number(userData.boostAdCredits || 0),
          );
          if (currentCredits < 2) {
            throw new HttpsError(
                "failed-precondition",
                "Watch two rewarded ads before activating a boost",
            );
          }
          boostAdCredits = currentCredits - 2;
          updates.boostAdCredits = boostAdCredits;
        }

        updates.boostSource = boostSource;
        transaction.update(userRef, updates);
      });

      return {
        success: true,
        expiresAt: expiresAt.getTime(),
        boostAdCredits,
        boostSource,
      };
    },
);

exports.applyPartnerCode = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const partnerCode = normalizePartnerCode(request.data?.partnerCode);
      if (!partnerCode) {
        throw new HttpsError("invalid-argument", "Partner code is required");
      }

      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);
      const partnerRef = db.collection("partner_organizations").doc(partnerCode);
      const ledgerRef = db.collection("partner_giveback_ledger")
          .doc(`${userId}_${partnerCode}`);
      let result = null;

      await db.runTransaction(async (transaction) => {
        const [userSnap, partnerSnap, ledgerSnap] = await Promise.all([
          transaction.get(userRef),
          transaction.get(partnerRef),
          transaction.get(ledgerRef),
        ]);

        if (!userSnap.exists) {
          throw new HttpsError("not-found", "User profile not found");
        }
        if (!partnerSnap.exists) {
          throw new HttpsError("not-found", "Partner code was not found");
        }

        const partner = partnerSnap.data() || {};
        if (partner.status !== "active") {
          throw new HttpsError(
              "failed-precondition",
              "Partner code is not active yet",
          );
        }

        const user = userSnap.data() || {};
        const previousPartnerCode = normalizePartnerCode(user.partnerCode);
        const isNewAttribution = !ledgerSnap.exists;
        const fieldValue = admin.firestore.FieldValue;
        const timestamp = fieldValue.serverTimestamp();

        transaction.set(userRef, {
          "partnerCode": partnerCode,
          "partnerCodeAttachedAt": timestamp,
          "partnerOrganizationName": partner.organizationName || null,
          "partnerGivebackLabel": partner.preferredGivebackLabel || null,
          "updatedAt": timestamp,
        }, {merge: true});

        if (isNewAttribution) {
          transaction.set(partnerRef, {
            "signupCount": fieldValue.increment(1),
            "lastSignupAt": timestamp,
            "updatedAt": timestamp,
          }, {merge: true});

          transaction.set(ledgerRef, {
            "type": "signup_attribution",
            "partnerCode": partnerCode,
            "organizationName": partner.organizationName || null,
            "organizationType": partner.organizationType || null,
            "organizationTypeLabel": partner.organizationTypeLabel || null,
            "preferredGiveback": partner.preferredGiveback || null,
            "preferredGivebackLabel": partner.preferredGivebackLabel || null,
            "previousPartnerCode": previousPartnerCode,
            "userId": userId,
            "eligibleRevenueCents": 0,
            "givebackCents": 0,
            "amountCents": 0,
            "source": "partner_code",
            "createdAt": timestamp,
            "updatedAt": timestamp,
          });
        }

        result = {
          partnerCode,
          organizationName: partner.organizationName || "Healthcare partner",
          organizationTypeLabel: partner.organizationTypeLabel || "Partner",
          preferredGiveback:
            partner.preferredGiveback || "nursing_scholarship",
          preferredGivebackLabel:
            partner.preferredGivebackLabel || "Nursing scholarship fund",
          status: partner.status,
          signupCount:
            Number(partner.signupCount || 0) + (isNewAttribution ? 1 : 0),
          eligibleRevenueCents: Number(partner.eligibleRevenueCents || 0),
          givebackCents: Number(partner.givebackCents || 0),
        };
      });

      return result;
    },
);

exports.recordCostTelemetry = onCall(
    {enforceAppCheck: true},
    async (request) => {
      const userId = request.auth?.uid;
      if (!userId) {
        throw new HttpsError("unauthenticated", "User must be authenticated");
      }

      const feature = requireString(request.data?.feature, "feature");
      const allowedFeatures = new Set([
        "chat_open",
        "discovery_deck_open",
        "profile_card_cache_miss",
      ]);
      if (!allowedFeatures.has(feature)) {
        throw new HttpsError("invalid-argument", "Unsupported telemetry feature");
      }

      const amount = Math.max(1, Math.min(100, Number(request.data?.amount) || 1));
      const unit = optionalString(request.data?.unit) || "event";
      await recordCostMetric(admin.firestore(), {
        feature,
        userId,
        amount,
        unit,
        metadata: sanitizeTelemetryMetadata(request.data?.metadata),
      });

      return {success: true};
    },
);

exports.recordStorageUsageMetric = onObjectFinalized(async (event) => {
  const object = event.data || {};
  const name = object.name || "";
  const sizeBytes = Number(object.size || 0);
  const userId = userIdFromStoragePath(name);
  if (!userId || sizeBytes <= 0) return;

  await recordCostMetric(admin.firestore(), {
    feature: "storage_upload",
    userId,
    amount: sizeBytes,
    unit: "bytes",
    metadata: {
      bucket: object.bucket || "",
      pathPrefix: storagePathPrefix(name),
      contentType: object.contentType || "",
    },
  });
});

exports.cleanupStaleOperationalData = onSchedule(
    {
      schedule: "every 60 minutes",
      timeZone: "America/Los_Angeles",
    },
    async () => {
      const db = admin.firestore();
      const now = Date.now();
      const staleWaitingCutoff = admin.firestore.Timestamp.fromMillis(
          now - staleSpeedRoomMinutes * 60 * 1000,
      );
      const staleActiveCutoff = admin.firestore.Timestamp.fromMillis(
          now - staleActiveRoomMinutes * 60 * 1000,
      );
      const completedVideoCutoff = admin.firestore.Timestamp.fromMillis(
          now - completedVideoRetentionDays * 24 * 60 * 60 * 1000,
      );
      const notificationCutoff = admin.firestore.Timestamp.fromMillis(
          now - notificationRetentionDays * 24 * 60 * 60 * 1000,
      );
      const expiredBoostCutoff = admin.firestore.Timestamp.fromMillis(
          now - expiredBoostRetentionDays * 24 * 60 * 60 * 1000,
      );

      const cleanup = {
        staleWaitingRooms:
          await clearSpeedRooms(db, "waiting", "updatedAt", staleWaitingCutoff),
        staleActiveRooms:
          await clearSpeedRooms(db, "active", "startedAt", staleActiveCutoff),
        completedVideoSessions: await deleteQuery(
            db.collection("video_sessions")
                .where("status", "in", ["completed", "ended", "missed"])
                .where("endedAt", "<", completedVideoCutoff)
                .limit(cleanupBatchSize),
        ),
        oldCallNotifications: await deleteQuery(
            db.collection("call_notifications")
                .where("createdAt", "<", notificationCutoff)
                .limit(cleanupBatchSize),
        ),
        expiredBoostLogs: await deleteQuery(
            db.collection("boostLogs")
                .where("expiresAt", "<", expiredBoostCutoff)
                .limit(cleanupBatchSize),
        ),
        oldMediaFiles: await cleanupOldMediaFiles(orphanedMediaRetentionDays),
      };

      await recordCostMetric(db, {
        feature: "scheduled_cleanup",
        userId: "system",
        amount: Object.values(cleanup).reduce(
            (total, value) => total + Number(value || 0),
            0,
        ),
        unit: "deleted_or_cleared",
        metadata: cleanup,
      });

      console.log("cleanupStaleOperationalData", cleanup);
      return cleanup;
    },
);

/**
 * Reads a required string field from callable data.
 * @param {*} value Raw callable value.
 * @param {string} fieldName Field name for error messages.
 * @return {string} Trimmed string value.
 */
function requireString(value, fieldName) {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${fieldName} is required`);
  }
  return value.trim();
}

/**
 * Reads an optional string field from callable data.
 * @param {*} value Raw callable value.
 * @return {?string} Trimmed string or null.
 */
function optionalString(value) {
  if (typeof value !== "string" || value.trim().length === 0) {
    return null;
  }
  return value.trim();
}

/**
 * Validates pending and final image paths for a moderated upload.
 * @param {Object} params Path validation details.
 * @return {void}
 */
function validateModeratedImagePaths(params) {
  const {userId, category, storagePath, destinationPath} = params;
  if (!isSafeStoragePath(storagePath) || !isSafeStoragePath(destinationPath)) {
    throw new HttpsError("invalid-argument", "Invalid storage path.");
  }
  if (!storagePath.startsWith(`pending_uploads/${userId}/`)) {
    throw new HttpsError("permission-denied", "Invalid pending upload path.");
  }
  if (category === "profile") {
    requirePathMatch(
        destinationPath,
        new RegExp(`^profile_images/${escapeRegExp(userId)}/profile\\.[a-z0-9]+$`),
    );
    return;
  }
  if (category === "gallery") {
    requirePathMatch(
        destinationPath,
        new RegExp(`^gallery_images/${escapeRegExp(userId)}/[^/]+\\.[a-z0-9]+$`),
    );
    return;
  }
  if (category === "post") {
    requirePathMatch(
        destinationPath,
        new RegExp(`^post_images/${escapeRegExp(userId)}/[^/]+\\.[a-z0-9]+$`),
    );
    return;
  }
  if (category === "chat") {
    requirePathMatch(destinationPath, /^chat_images\/[^/]+\/[^/]+\.[a-z0-9]+$/);
    return;
  }
  throw new HttpsError("invalid-argument", "Unsupported image category.");
}

/**
 * Checks a path against a regex and throws a callable error on mismatch.
 * @param {string} value Storage path.
 * @param {RegExp} pattern Required pattern.
 * @return {void}
 */
function requirePathMatch(value, pattern) {
  if (!pattern.test(value)) {
    throw new HttpsError("permission-denied", "Invalid destination path.");
  }
}

/**
 * Rejects traversal, empty segments, and unexpected path roots.
 * @param {string} path Storage object path.
 * @return {boolean} Whether the path is safe.
 */
function isSafeStoragePath(path) {
  return /^[A-Za-z0-9._/-]+$/.test(path) &&
    !path.includes("..") &&
    !path.includes("//") &&
    !path.startsWith("/") &&
    !path.endsWith("/");
}

/**
 * Escapes text for use inside a regular expression.
 * @param {string} value Raw text.
 * @return {string} Escaped text.
 */
function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Calls Google Cloud Vision SafeSearch detection for one image.
 * @param {Buffer} imageBytes Uploaded image bytes.
 * @return {Promise<Object>} SafeSearch annotation.
 */
async function analyzeImageSafety(imageBytes) {
  const client = await visionAuth.getClient();
  const headers = await client.getRequestHeaders();
  const response = await fetch(
      "https://vision.googleapis.com/v1/images:annotate",
      {
        method: "POST",
        headers: {
          ...headers,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          requests: [{
            image: {content: imageBytes.toString("base64")},
            features: [{type: "SAFE_SEARCH_DETECTION", maxResults: 1}],
          }],
        }),
      },
  );
  const body = await response.json();
  if (!response.ok || !body.responses || body.responses[0].error) {
    throw new Error(JSON.stringify(body));
  }
  return body.responses[0].safeSearchAnnotation || {};
}

/**
 * Returns true when SafeSearch detects nudity or strongly unsafe content.
 * @param {Object} safety SafeSearch annotation.
 * @return {boolean} Whether the image should be rejected.
 */
function isUnsafeImage(safety) {
  return likelihoodRank(safety.adult) >= safeSearchRanks.POSSIBLE ||
    likelihoodRank(safety.racy) >= safeSearchRanks.LIKELY ||
    likelihoodRank(safety.violence) >= safeSearchRanks.LIKELY;
}

/**
 * Converts a SafeSearch likelihood to a comparable rank.
 * @param {?string} likelihood SafeSearch likelihood.
 * @return {number} Numeric rank.
 */
function likelihoodRank(likelihood) {
  return safeSearchRanks[likelihood || "UNKNOWN"] || 0;
}

/**
 * Writes an audit log for photo moderation decisions.
 * @param {Object} params Moderation log fields.
 * @return {Promise<void>}
 */
async function logImageModeration(params) {
  await admin.firestore().collection("image_moderation_logs").add({
    userId: params.userId,
    category: params.category,
    storagePath: params.storagePath,
    destinationPath: params.destinationPath,
    safety: params.safety,
    status: params.status,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Builds a Firebase Storage token download URL.
 * @param {string} bucketName Storage bucket name.
 * @param {string} path Storage object path.
 * @param {string} token Download token.
 * @return {string} Download URL.
 */
function firebaseDownloadUrl(bucketName, path, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/` +
    `${encodeURIComponent(path)}?alt=media&token=${token}`;
}

/**
 * Stores daily cost telemetry in aggregate and per-user counter documents.
 * @param {FirebaseFirestore.Firestore} db Firestore instance.
 * @param {Object} params Metric details.
 * @return {Promise<void>}
 */
async function recordCostMetric(db, params) {
  const feature = safeMetricKey(params.feature);
  const userId = safeMetricKey(params.userId || "unknown");
  const amount = Math.max(0, Number(params.amount) || 0);
  if (!feature || amount <= 0) return;

  const unit = optionalString(params.unit) || "event";
  const day = dayKey();
  const fieldValue = admin.firestore.FieldValue;
  const timestamp = fieldValue.serverTimestamp();
  const aggregateRef = db
      .collection("cost_metrics")
      .doc(day)
      .collection("features")
      .doc(feature);
  const userRef = aggregateRef.collection("users").doc(userId);
  const payload = {
    feature,
    unit,
    updatedAt: timestamp,
    eventCount: fieldValue.increment(1),
    totalAmount: fieldValue.increment(amount),
    [`units.${safeMetricKey(unit)}`]: fieldValue.increment(amount),
  };
  const userPayload = {
    ...payload,
    userId,
    lastMetadata: sanitizeTelemetryMetadata(params.metadata),
  };

  const batch = db.batch();
  batch.set(aggregateRef, payload, {merge: true});
  batch.set(userRef, userPayload, {merge: true});
  await batch.commit();
}

/**
 * Keeps telemetry metadata compact and safe for Firestore counter docs.
 * @param {*} metadata Raw metadata.
 * @return {Object} Sanitized metadata.
 */
function sanitizeTelemetryMetadata(metadata) {
  if (!metadata || typeof metadata !== "object" || Array.isArray(metadata)) {
    return {};
  }
  const clean = {};
  for (const [key, value] of Object.entries(metadata).slice(0, 12)) {
    const cleanKey = safeMetricKey(key);
    if (!cleanKey) continue;
    if (typeof value === "string") {
      clean[cleanKey] = value.slice(0, 160);
    } else if (typeof value === "number" || typeof value === "boolean") {
      clean[cleanKey] = value;
    }
  }
  return clean;
}

/**
 * Makes a stable Firestore-safe metric key.
 * @param {*} value Raw key.
 * @return {string} Safe key.
 */
function safeMetricKey(value) {
  return String(value || "")
      .trim()
      .replace(/[^A-Za-z0-9_-]/g, "_")
      .slice(0, 80);
}

/**
 * Clears stale speed-dating room presence without deleting room definitions.
 * @param {FirebaseFirestore.Firestore} db Firestore instance.
 * @param {string} status Room status.
 * @param {string} field Timestamp field to compare.
 * @param {FirebaseFirestore.Timestamp} cutoff Cleanup cutoff.
 * @return {Promise<number>} Number of cleared rooms.
 */
async function clearSpeedRooms(db, status, field, cutoff) {
  const snapshot = await db.collection("speed_dating_rooms")
      .where("status", "==", status)
      .where(field, "<", cutoff)
      .orderBy(field)
      .limit(cleanupBatchSize)
      .get();
  if (snapshot.empty) return 0;

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.set(doc.ref, speedRoomClearedFields("scheduled_cleanup"), {
      merge: true,
    });
  });
  await batch.commit();
  return snapshot.size;
}

/**
 * Deletes all docs returned by a bounded query.
 * @param {FirebaseFirestore.Query} query Firestore query.
 * @return {Promise<number>} Deleted count.
 */
async function deleteQuery(query) {
  const snapshot = await query.get();
  if (snapshot.empty) return 0;
  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  return snapshot.size;
}

/**
 * Deletes old temporary media objects only; user-visible media is preserved.
 * @param {number} retentionDays Retention period in days.
 * @return {Promise<number>} Deleted file count.
 */
async function cleanupOldMediaFiles(retentionDays) {
  const bucket = admin.storage().bucket();
  const cutoffMs = Date.now() - retentionDays * 24 * 60 * 60 * 1000;
  const prefixes = ["tmp/", "temp_uploads/", "uploads/tmp/"];
  let deleted = 0;

  for (const prefix of prefixes) {
    const [files] = await bucket.getFiles({prefix, maxResults: 200});
    for (const file of files) {
      const metadata = file.metadata || {};
      const updated = Date.parse(metadata.updated || metadata.timeCreated || "");
      if (!Number.isFinite(updated) || updated > cutoffMs) continue;
      await file.delete({ignoreNotFound: true});
      deleted += 1;
    }
  }

  return deleted;
}

/**
 * Extracts the owner ID from app-managed storage paths.
 * @param {string} name Storage object path.
 * @return {?string} User ID or null.
 */
function userIdFromStoragePath(name) {
  const parts = String(name || "").split("/");
  const userScopedPrefixes = new Set([
    "profile_images",
    "gallery_images",
    "post_images",
    "verification",
  ]);
  if (userScopedPrefixes.has(parts[0]) && parts[1]) {
    return parts[1];
  }
  if (parts[0] === "chats" && parts.length >= 4) {
    return "chat_media";
  }
  return null;
}

/**
 * Returns a compact storage path category for telemetry.
 * @param {string} name Storage object path.
 * @return {string} Path prefix.
 */
function storagePathPrefix(name) {
  const parts = String(name || "").split("/");
  if (parts[0] === "chats" && parts[2]) return `chats_${parts[2]}`;
  return parts[0] || "unknown";
}

/**
 * Current UTC day key for metric docs.
 * @return {string} Date key.
 */
function dayKey() {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Normalizes a partner code to the canonical Firestore document ID.
 * @param {*} value Raw partner code.
 * @return {?string} Normalized partner code or null.
 */
function normalizePartnerCode(value) {
  const raw = optionalString(value);
  if (!raw) return null;
  const code = raw.toUpperCase().replace(/[^A-Z0-9_-]/g, "");
  return code.length > 0 ? code : null;
}

/**
 * Verifies an optional client-sent user ID matches auth.
 * @param {*} clientUserId Optional user ID sent by the app.
 * @param {string} authUserId Firebase Auth UID from callable context.
 */
function assertClientUserMatchesAuth(clientUserId, authUserId) {
  const value = optionalString(clientUserId);
  if (value && value !== authUserId) {
    throw new HttpsError("permission-denied", "User ID mismatch");
  }
}

/**
 * Returns usage limits for a stored plan.
 * @param {*} planValue User plan value from Firestore.
 * @return {Object} Usage limit configuration.
 */
function planUsageLimits(planValue) {
  const plan = optionalString(planValue) || "free";
  return usagePlanFeatures[plan] || usagePlanFeatures.free;
}

/**
 * Returns usage event bookkeeping fields.
 * @param {string} eventType Usage event type.
 * @param {?string} planValue Current app subscription plan.
 * @return {Object} Usage event config.
 */
function usageEventConfig(eventType, planValue) {
  const plan = optionalString(planValue) || "free";

  if (eventType === "message") {
    return {
      docId: () => `daily_${dateKey()}`,
      usageField: "messagesSent",
      refillField: "messagesRefilled",
      limitField: "dailyMessages",
      usageType: "messages",
      statsField: "stats.messagesSent",
    };
  }

  if (eventType === "like") {
    return {
      docId: () => `daily_${dateKey()}`,
      usageField: "likesSent",
      refillField: "likesRefilled",
      limitField: "dailyLikes",
      usageType: "likes",
      statsField: "stats.likesSent",
      targetStatsField: "stats.likesReceived",
    };
  }

  if (eventType === "superlike") {
    if (plan === "tech") {
      return {
        docId: () => `daily_${dateKey()}`,
        usageField: "superLikesSent",
        refillField: null,
        limitField: "dailySuperLikes",
        usageType: "superlikes",
        statsField: "stats.likesSent",
        targetStatsField: "stats.likesReceived",
      };
    }

    return {
      docId: () => `monthly_${monthKey()}`,
      usageField: "superLikesSent",
      refillField: null,
      limitField: "monthlySuperLikes",
      usageType: "superlikes",
      statsField: "stats.likesSent",
      targetStatsField: "stats.likesReceived",
    };
  }

  if (eventType === "rewind") {
    return {
      docId: () => `daily_${dateKey()}`,
      usageField: "rewindsUsed",
      refillField: "rewindsRefilled",
      limitField: "dailyRewinds",
      usageType: "rewinds",
      statsField: "stats.rewindsUsed",
    };
  }

  throw new HttpsError("invalid-argument", "Unsupported usage event type");
}

/**
 * Computes plan usage state for an event.
 * @param {Object} userData User document data.
 * @param {Object} usageData Usage document data.
 * @param {Object} config Usage event config.
 * @return {Object} Usage state.
 */
function usageLimitState(userData, usageData, config) {
  const plan = optionalString(userData.plan) || "free";
  const limits = planUsageLimits(plan);
  const baseLimit = Number(limits[config.limitField]);
  const used = Number(usageData[config.usageField] || 0);
  const refilled = config.refillField ?
    Number(usageData[config.refillField] || 0) :
    0;
  const effectiveLimit = baseLimit === -1 ? -1 : baseLimit + refilled;
  return {plan, baseLimit, used, refilled, effectiveLimit};
}

/**
 * Throws when a plan usage limit has been exhausted.
 * @param {Object} state Usage state from usageLimitState.
 * @param {Object} config Usage event config.
 * @param {string} eventType Raw event type.
 * @return {number} Remaining usage after one new event.
 */
function assertUsageAvailable(state, config, eventType) {
  if (state.effectiveLimit !== -1 && state.used + 1 > state.effectiveLimit) {
    throw new HttpsError(
        "resource-exhausted",
        `${config.usageType || eventType} limit reached`,
        {
          usageType: config.usageType || eventType,
          plan: state.plan,
          limit: state.effectiveLimit,
          used: state.used,
        },
    );
  }
  return state.effectiveLimit === -1 ? 999 : state.effectiveLimit - state.used - 1;
}

/**
 * Increments usage and optional recipient stats inside a transaction.
 * @param {Object} transaction Firestore transaction.
 * @param {Object} userRef User document reference.
 * @param {Object} usageRef Usage document reference.
 * @param {Object} config Usage event config.
 * @param {?Object} targetRef Optional target user reference.
 */
function incrementUsage(transaction, userRef, usageRef, config, targetRef) {
  transaction.set(usageRef, {
    [config.usageField]: admin.firestore.FieldValue.increment(1),
    "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
  transaction.set(userRef, {
    [config.statsField]: admin.firestore.FieldValue.increment(1),
    "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  if (config.targetStatsField && targetRef) {
    transaction.set(targetRef, {
      [config.targetStatsField]: admin.firestore.FieldValue.increment(1),
      "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  }
}

/**
 * Returns true when either user has blocked the other.
 * @param {Object} userData Current user data.
 * @param {Object} otherData Other user data.
 * @param {string} userId Current user ID.
 * @param {string} otherUserId Other user ID.
 * @return {boolean} Block relationship status.
 */
function isBlockedBetween(userData, otherData, userId, otherUserId) {
  const userBlocked = Array.isArray(userData.blocked) ? userData.blocked : [];
  const otherBlocked = Array.isArray(otherData.blocked) ? otherData.blocked : [];
  return userBlocked.includes(otherUserId) || otherBlocked.includes(userId);
}

/**
 * Deletes chats and messages between two users after a block.
 * @param {Object} db Firestore instance.
 * @param {string} userA First user ID.
 * @param {string} userB Second user ID.
 * @return {Promise<number>} Deleted chat count.
 */
async function deletePairChats(db, userA, userB) {
  const chats = await db.collection("chats")
      .where("participants", "array-contains", userA)
      .get();
  let deletedChats = 0;

  for (const chat of chats.docs) {
    const participants = Array.isArray(chat.data().participants) ?
      chat.data().participants :
      [];
    if (!participants.includes(userB)) continue;

    const messages = await chat.ref.collection("messages").get();
    let batch = db.batch();
    let writes = 0;

    for (const message of messages.docs) {
      batch.delete(message.ref);
      writes++;
      if (writes >= 450) {
        await batch.commit();
        batch = db.batch();
        writes = 0;
      }
    }

    batch.delete(chat.ref);
    await batch.commit();
    deletedChats++;
  }

  return deletedChats;
}

/**
 * Returns a safe public display name.
 * @param {Object} userData User document data.
 * @return {string} Name.
 */
function publicUserName(userData) {
  return optionalString(userData.name) || "Nurse";
}

/**
 * Returns a safe public photo URL.
 * @param {Object} userData User document data.
 * @return {?string} Photo URL.
 */
function publicUserPhoto(userData) {
  return optionalString(userData.photoUrl);
}

/**
 * Returns the next rewarded-ad milestone for earning video minutes.
 * @param {number} adsWatchedToday Ads watched today.
 * @return {?Object} Next milestone, or null when the daily ladder is complete.
 */
function nextVideoAdMilestone(adsWatchedToday) {
  for (const count of [10, 50, 200]) {
    if (adsWatchedToday < count) {
      return {
        ads: count,
        minutes: videoAdMinuteMilestones[count],
        remainingAds: count - adsWatchedToday,
      };
    }
  }
  return null;
}

/**
 * Builds chat list preview copy for a message.
 * @param {string} type Message type.
 * @param {string} content Message content.
 * @param {*} giftName Optional gift name.
 * @return {string} Preview text.
 */
function chatMessagePreview(type, content, giftName) {
  if (type === "image") return "Photo";
  if (type === "gift") return `Gift: ${optionalString(giftName) || "Gift"}`;
  if (type === "videoCall") return "Video Call";
  if (type === "voiceNote") return "Voice Note";
  return content;
}

/**
 * Rejects voice notes that exceed the product max length.
 * @param {string} content Message content in mm:ss|url format.
 */
function assertVoiceNoteDurationAllowed(content) {
  const durationText = String(content).split("|")[0] || "";
  const match = durationText.match(/^(\d{1,2}):([0-5]\d)$/);
  if (!match) {
    throw new HttpsError("invalid-argument", "Voice note duration is required");
  }

  const seconds = Number(match[1]) * 60 + Number(match[2]);
  if (seconds < 1 || seconds > maxVoiceMessageSeconds) {
    throw new HttpsError(
        "invalid-argument",
        `Voice messages can be ${maxVoiceMessageSeconds} seconds max`,
    );
  }
}

/**
 * Returns ad-refill fields for daily usage counters.
 * @param {string} usageType Refillable usage type.
 * @return {Object} Refill config.
 */
function usageRefillConfig(usageType) {
  if (usageType === "messages") {
    return {
      refillField: "messagesRefilled",
      claimsField: "messageRefillClaims",
    };
  }

  if (usageType === "likes") {
    return {
      refillField: "likesRefilled",
      claimsField: "likeRefillClaims",
    };
  }

  if (usageType === "rewinds") {
    return {
      refillField: "rewindsRefilled",
      claimsField: "rewindRefillClaims",
    };
  }

  throw new HttpsError("invalid-argument", "Unsupported usage refill type");
}

/**
 * Extracts unique speed-room participant IDs from slot and list fields.
 * @param {Object} room Speed dating room data.
 * @return {Array<string>} Unique participant IDs.
 */
function speedRoomParticipants(room) {
  const ids = new Set();
  for (const key of ["user1Id", "user2Id"]) {
    const value = room[key];
    if (typeof value === "string" && value.length > 0) {
      ids.add(value);
    }
  }

  if (Array.isArray(room.currentParticipants)) {
    for (const value of room.currentParticipants) {
      if (typeof value === "string" && value.length > 0) {
        ids.add(value);
      }
    }
  }

  return Array.from(ids);
}

/**
 * Finds the first open user slot in a room.
 * @param {Object} room Speed dating room data.
 * @return {string} Slot prefix, `user1` or `user2`.
 */
function speedRoomFirstOpenSlot(room) {
  const user1Id = room.user1Id;
  if (typeof user1Id !== "string" || user1Id.length === 0) {
    return "user1";
  }
  return "user2";
}

/**
 * Returns true when a room should be force-reset before another action.
 * @param {Object} room Speed dating room data.
 * @return {boolean} Whether the room is stale.
 */
function speedRoomShouldReset(room) {
  const participants = speedRoomParticipants(room);
  if (participants.length === 0) {
    return false;
  }

  const currentParticipants = Array.isArray(room.currentParticipants) ?
    room.currentParticipants.filter((id) =>
      typeof id === "string" && id.length > 0,
    ) :
    [];
  if (currentParticipants.length === 0) return true;

  if (room.status !== "active") {
    return speedRoomWaitingIsStale(room);
  }
  const startedAt = room.startedAt;
  if (!startedAt || typeof startedAt.toDate !== "function") return true;
  const duration = Math.max(1, Number(room.duration || 5));
  const startedAtMs = startedAt.toDate().getTime();
  return Date.now() - startedAtMs > (duration + 1) * 60 * 1000;
}

/**
 * Returns true when a waiting room is holding stale presence.
 * @param {Object} room Speed dating room data.
 * @return {boolean} Whether the waiting room is stale.
 */
function speedRoomWaitingIsStale(room) {
  if (room.status !== "waiting") return false;
  const timestamp =
    room.lastJoinedAt ||
    room.updatedAt ||
    room.createdAt ||
    null;
  if (!timestamp || typeof timestamp.toDate !== "function") return false;
  return Date.now() - timestamp.toDate().getTime() > 5 * 60 * 1000;
}

/**
 * Returns fields that reset a speed-dating room to empty waiting state.
 * @param {string} endedByUserId User who triggered cleanup.
 * @return {Object} Firestore merge fields.
 */
function speedRoomClearedFields(endedByUserId) {
  return {
    "status": "waiting",
    "startedAt": null,
    "activeSessionId": null,
    "lastEndedAt": admin.firestore.FieldValue.serverTimestamp(),
    "lastEndedBy": endedByUserId,
    "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
    "currentParticipants": [],
    "user1Id": null,
    "user1Name": null,
    "user1PhotoUrl": null,
    "user1Age": null,
    "user2Id": null,
    "user2Name": null,
    "user2PhotoUrl": null,
    "user2Age": null,
  };
}

/**
 * Fetches a RevenueCat v1 subscriber record for a Firebase UID.
 * @param {string} userId Firebase Auth UID used as RevenueCat app_user_id.
 * @return {Promise<Object>} RevenueCat subscriber payload.
 */
async function fetchRevenueCatSubscriber(userId) {
  const apiKey = revenueCatApiKey.value();
  if (!apiKey) {
    throw new HttpsError(
        "failed-precondition",
        "RevenueCat secret is not configured",
    );
  }

  const response = await global.fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
      {
        headers: {
          "Accept": "application/json",
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
      },
  );

  const responseText = await response.text();
  let body = {};
  if (responseText) {
    try {
      body = JSON.parse(responseText);
    } catch (error) {
      throw new HttpsError(
          "internal",
          "RevenueCat returned an unreadable response",
      );
    }
  }

  if (!response.ok) {
    const message = typeof body.message === "string" ?
      body.message :
      "RevenueCat sync failed";
    throw new HttpsError("failed-precondition", message);
  }

  return body.subscriber || {};
}

/**
 * Extracts consumable video-minute purchases from RevenueCat state.
 * @param {string} userId Firebase Auth UID.
 * @param {Object} subscriber RevenueCat subscriber payload.
 * @return {Array<Object>} Purchase credit candidates.
 */
function revenueCatMinutePurchases(userId, subscriber) {
  const nonSubscriptions = subscriber.non_subscriptions || {};
  const purchases = [];

  Object.entries(nonSubscriptions).forEach(([productId, productPurchases]) => {
    const minutes = videoMinuteProducts[productId];
    if (!minutes || !Array.isArray(productPurchases)) return;

    productPurchases.forEach((purchase, index) => {
      const purchaseId = revenueCatPurchaseId(productId, purchase, index);
      purchases.push({
        productId,
        purchaseId,
        minutes,
        creditId: purchaseCreditId(userId, productId, purchaseId),
      });
    });
  });

  return purchases;
}

/**
 * Builds partner-attributable RevenueCat revenue events.
 * @param {Object} params Revenue attribution inputs.
 * @return {Array<Object>} Revenue events for partner ledger creation.
 */
function revenueCatPartnerRevenueEvents(params) {
  const events = [];
  const subscriptionEvent = revenueCatSubscriptionRevenueEvent(
      params.userId,
      params.subscriber,
      params.plan,
  );
  if (subscriptionEvent) {
    events.push(subscriptionEvent);
  }

  params.purchases.forEach((purchase) => {
    const revenueCents = productRevenueCents[purchase.productId] || 0;
    if (revenueCents <= 0) return;
    events.push({
      eventId: purchase.creditId,
      type: "video_minutes_purchase",
      productId: purchase.productId,
      purchaseId: purchase.purchaseId,
      revenueCents,
    });
  });

  return events;
}

/**
 * Creates one subscription revenue event per active RevenueCat period.
 * @param {string} userId Firebase Auth UID.
 * @param {Object} subscriber RevenueCat subscriber payload.
 * @param {string} plan App subscription plan.
 * @return {?Object} Subscription revenue event or null.
 */
function revenueCatSubscriptionRevenueEvent(userId, subscriber, plan) {
  const fallbackProductId = subscriptionProductIdsByPlan[plan];
  if (!fallbackProductId) return null;

  const entitlement = revenueCatSubscriptionEntitlement(subscriber, plan);
  const productId = optionalString(entitlement?.product_identifier) ||
    fallbackProductId;
  const revenueCents =
    productRevenueCents[productId] || productRevenueCents[fallbackProductId];
  if (!revenueCents || revenueCents <= 0) return null;

  const periodId = revenueCatSubscriptionPeriodId(productId, entitlement);
  return {
    eventId: purchaseCreditId(userId, productId, periodId),
    type: "subscription_revenue",
    productId,
    purchaseId: periodId,
    revenueCents,
  };
}

/**
 * Finds the active entitlement that produced the app plan.
 * @param {Object} subscriber RevenueCat subscriber payload.
 * @param {string} plan App subscription plan.
 * @return {?Object} Matching entitlement payload or null.
 */
function revenueCatSubscriptionEntitlement(subscriber, plan) {
  const entitlements = subscriber.entitlements || {};
  for (const [entitlementId, entitlementPlan] of Object.entries(
      entitlementPlans,
  )) {
    const entitlement = entitlements[entitlementId];
    if (entitlementPlan === plan && isRevenueCatEntitlementActive(entitlement)) {
      return entitlement;
    }
  }
  return null;
}

/**
 * Returns a stable period key for subscription attribution.
 * @param {string} productId RevenueCat product identifier.
 * @param {?Object} entitlement RevenueCat entitlement payload.
 * @return {string} Stable period identifier.
 */
function revenueCatSubscriptionPeriodId(productId, entitlement) {
  const rawPeriod = entitlement?.expires_date_ms ||
    entitlement?.expires_date ||
    entitlement?.expires_date_iso ||
    entitlement?.purchase_date_ms ||
    entitlement?.purchase_date ||
    monthKey();
  const normalized = String(rawPeriod).replace(/[^A-Za-z0-9_-]/g, "_");
  return `${productId}_${normalized}`;
}

/**
 * Creates a compact Firestore ID for partner revenue ledger entries.
 * @param {string} userId Firebase Auth UID.
 * @param {string} partnerCode Normalized partner code.
 * @param {string} eventId Revenue event identifier.
 * @return {string} SHA-256 document ID.
 */
function partnerRevenueLedgerId(userId, partnerCode, eventId) {
  return crypto
      .createHash("sha256")
      .update(`${userId}|${partnerCode}|${eventId}`)
      .digest("hex");
}

/**
 * Calculates the giveback amount for a partner revenue event.
 * @param {number} revenueCents Eligible revenue in cents.
 * @param {Object} partner Partner organization document.
 * @return {number} Giveback amount in cents.
 */
function partnerGivebackCents(revenueCents, partner) {
  const configuredBps = Number(partner.givebackRateBps);
  const rateBps = Number.isFinite(configuredBps) &&
    configuredBps > 0 &&
    configuredBps <= 10000 ?
    configuredBps :
    defaultPartnerGivebackRateBps;
  return Math.round((revenueCents * rateBps) / 10000);
}

/**
 * Writes partner revenue ledger entries and aggregate impact counters.
 * @param {Object} params Transaction write inputs.
 */
function recordPartnerRevenueEvents(params) {
  const fieldValue = admin.firestore.FieldValue;
  const timestamp = fieldValue.serverTimestamp();
  let eligibleRevenueCents = 0;
  let givebackCents = 0;
  let eventCount = 0;

  params.ledgerRefs.forEach(({event, ref}, index) => {
    if (params.ledgerSnaps[index].exists) return;
    const eventGivebackCents = partnerGivebackCents(
        event.revenueCents,
        params.partner,
    );

    eligibleRevenueCents += event.revenueCents;
    givebackCents += eventGivebackCents;
    eventCount += 1;

    params.transaction.set(ref, {
      "type": event.type,
      "partnerCode": params.partnerCode,
      "organizationName": params.partner.organizationName || null,
      "organizationType": params.partner.organizationType || null,
      "organizationTypeLabel": params.partner.organizationTypeLabel || null,
      "preferredGiveback": params.partner.preferredGiveback || null,
      "preferredGivebackLabel": params.partner.preferredGivebackLabel || null,
      "userId": params.userId,
      "productId": event.productId,
      "purchaseId": event.purchaseId,
      "eligibleRevenueCents": event.revenueCents,
      "givebackCents": eventGivebackCents,
      "amountCents": event.revenueCents,
      "source": "revenuecat",
      "createdAt": timestamp,
      "updatedAt": timestamp,
    });
  });

  if (eventCount === 0) return;

  params.transaction.set(params.partnerRef, {
    "eligibleRevenueCents": fieldValue.increment(eligibleRevenueCents),
    "givebackCents": fieldValue.increment(givebackCents),
    "impactUpdatesCount": fieldValue.increment(eventCount),
    "lastRevenueAt": timestamp,
    "updatedAt": timestamp,
  }, {merge: true});
}

/**
 * Returns a stable purchase identifier from RevenueCat's flexible payload.
 * @param {string} productId RevenueCat product identifier.
 * @param {Object} purchase RevenueCat non-subscription purchase.
 * @param {number} index Purchase index fallback.
 * @return {string} Stable purchase identifier.
 */
function revenueCatPurchaseId(productId, purchase, index) {
  if (!purchase || typeof purchase !== "object") {
    return `${productId}_${index}`;
  }

  return String(
      purchase.id ||
      purchase.store_transaction_id ||
      purchase.transaction_id ||
      purchase.purchase_id ||
      purchase.original_transaction_id ||
      purchase.purchase_date_ms ||
      purchase.purchase_date ||
      `${productId}_${index}`,
  );
}

/**
 * Creates a compact Firestore ID for a purchase credit.
 * @param {string} userId Firebase Auth UID.
 * @param {string} productId Product identifier.
 * @param {string} purchaseId Store or RevenueCat purchase identifier.
 * @return {string} SHA-256 document ID.
 */
function purchaseCreditId(userId, productId, purchaseId) {
  return crypto
      .createHash("sha256")
      .update(`${userId}|${productId}|${purchaseId}`)
      .digest("hex");
}

/**
 * Returns the current UTC date key.
 * @return {string} YYYY-MM-DD date key.
 */
function dateKey() {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Returns the current UTC month key.
 * @return {string} YYYY-MM month key.
 */
function monthKey() {
  return new Date().toISOString().slice(0, 7);
}

/**
 * Helper function to send notification to a specific FCM token
 * @param {string} token - FCM token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {Object} data - Additional data payload
 */
async function sendNotificationToUser(token, title, body, data) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: data,
    token: token,
    android: {
      priority: "high",
      notification: {
        channelId: data.type === "new_message" ? "messages" :
          data.type === "new_like" ? "likes" : "matches",
        sound: "default",
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`Notification sent successfully: ${response}`);
    return response;
  } catch (error) {
    console.error(`Error sending notification: ${error}`);
    throw error;
  }
}
