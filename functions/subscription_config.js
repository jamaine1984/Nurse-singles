const entitlementPlans = {
  "nurse_singles_pro": "nurse",
  "Nurse Singles Pro": "nurse",
  "nurse_singles_pro_entitlement": "nurse",
  "pro": "nurse",
  "doctor_tier": "doctor",
  "nurse_tier": "nurse",
  "college_tier": "college",
  "tech_tier": "tech",
};

const planRank = {
  "free": 0,
  "tech": 1,
  "college": 2,
  "nurse": 3,
  "doctor": 4,
};

const usagePlanFeatures = {
  "free": {
    dailyMessages: 3,
    dailyLikes: 3,
    monthlySuperLikes: 1,
    monthlyVideoMinutes: 0,
    dailyRewinds: 3,
  },
  "tech": {
    dailyMessages: 10,
    dailyLikes: 10,
    dailySuperLikes: 3,
    monthlySuperLikes: 0,
    monthlyVideoMinutes: 30,
    dailyRewinds: 10,
  },
  "college": {
    dailyMessages: -1,
    dailyLikes: 25,
    monthlySuperLikes: 5,
    monthlyVideoMinutes: 300,
    dailyRewinds: -1,
  },
  "nurse": {
    dailyMessages: -1,
    dailyLikes: -1,
    monthlySuperLikes: -1,
    monthlyVideoMinutes: 1000,
    dailyRewinds: -1,
  },
  "doctor": {
    dailyMessages: -1,
    dailyLikes: -1,
    monthlySuperLikes: -1,
    monthlyVideoMinutes: 3500,
    dailyRewinds: -1,
  },
};

const videoMinuteProducts = {
  "video_minutes_400": 400,
  "video_minutes_800": 800,
  "video_minutes_2500": 2500,
};

const productRevenueCents = {
  "monthly": 999,
  "monthly:monthly": 999,
  "tech_monthly": 199,
  "tech_monthly:monthly": 199,
  "college_monthly": 499,
  "college_monthly:monthly": 499,
  "nurse_monthly": 1499,
  "nurse_monthly:monthly": 1499,
  "doctor_monthly": 3999,
  "doctor_monthly:monthly": 3999,
  "video_minutes_400": 499,
  "video_minutes_800": 999,
  "video_minutes_2500": 1999,
};

/**
 * Checks if a RevenueCat v1 entitlement is still active.
 * @param {Object} entitlement RevenueCat entitlement payload.
 * @return {boolean} Whether the entitlement currently grants access.
 */
function isRevenueCatEntitlementActive(entitlement) {
  if (!entitlement || typeof entitlement !== "object") return false;

  const expiresAt = entitlement.expires_date ||
    entitlement.expires_date_ms ||
    entitlement.expires_date_iso;
  if (!expiresAt) return true;

  const expiresAtMs = typeof expiresAt === "number" ?
    expiresAt :
    Date.parse(expiresAt);
  return Number.isFinite(expiresAtMs) && expiresAtMs > Date.now();
}

/**
 * Maps RevenueCat active entitlements to the app subscription plan.
 * @param {Object} subscriber RevenueCat subscriber payload.
 * @return {string} App plan value.
 */
function planFromRevenueCatSubscriber(subscriber) {
  const entitlements = subscriber.entitlements || {};
  let bestPlan = "free";

  Object.entries(entitlements).forEach(([entitlementId, entitlement]) => {
    const plan = entitlementPlans[entitlementId];
    if (!plan || !isRevenueCatEntitlementActive(entitlement)) return;
    if (planRank[plan] > planRank[bestPlan]) {
      bestPlan = plan;
    }
  });

  return bestPlan;
}

module.exports = {
  entitlementPlans,
  planRank,
  usagePlanFeatures,
  videoMinuteProducts,
  productRevenueCents,
  isRevenueCatEntitlementActive,
  planFromRevenueCatSubscriber,
};
