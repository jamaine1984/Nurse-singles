const assert = require("node:assert/strict");
const test = require("node:test");
const {
  usagePlanFeatures,
  productRevenueCents,
  planFromRevenueCatSubscriber,
  isRevenueCatEntitlementActive,
} = require("./subscription_config");

test("free plan limits are enforced", () => {
  assert.deepEqual(usagePlanFeatures.free, {
    dailyMessages: 3,
    dailyLikes: 3,
    monthlySuperLikes: 1,
    monthlyVideoMinutes: 0,
    dailyRewinds: 3,
  });
});

test("tech plan limits are enforced", () => {
  assert.deepEqual(usagePlanFeatures.tech, {
    dailyMessages: 10,
    dailyLikes: 10,
    dailySuperLikes: 3,
    monthlySuperLikes: 0,
    monthlyVideoMinutes: 30,
    dailyRewinds: 10,
  });
});

test("college plan limits are enforced", () => {
  assert.deepEqual(usagePlanFeatures.college, {
    dailyMessages: -1,
    dailyLikes: 25,
    monthlySuperLikes: 5,
    monthlyVideoMinutes: 300,
    dailyRewinds: -1,
  });
});

test("nurse and doctor plans have unlimited premium usage", () => {
  assert.deepEqual(usagePlanFeatures.nurse, {
    dailyMessages: -1,
    dailyLikes: -1,
    monthlySuperLikes: -1,
    monthlyVideoMinutes: 1000,
    dailyRewinds: -1,
  });
  assert.deepEqual(usagePlanFeatures.doctor, {
    dailyMessages: -1,
    dailyLikes: -1,
    monthlySuperLikes: -1,
    monthlyVideoMinutes: 3500,
    dailyRewinds: -1,
  });
});

test("RevenueCat entitlements map to the highest active tier", () => {
  const future = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const expired = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  assert.equal(planFromRevenueCatSubscriber({
    entitlements: {
      tech_tier: {expires_date: future},
    },
  }), "tech");

  assert.equal(planFromRevenueCatSubscriber({
    entitlements: {
      nurse_tier: {expires_date: future},
      doctor_tier: {expires_date: expired},
    },
  }), "nurse");

  assert.equal(planFromRevenueCatSubscriber({
    entitlements: {
      nurse_tier: {expires_date: future},
      doctor_tier: {expires_date: future},
    },
  }), "doctor");
});

test("RevenueCat active entitlement date handling is strict", () => {
  assert.equal(isRevenueCatEntitlementActive({}), true);
  assert.equal(isRevenueCatEntitlementActive({
    expires_date: new Date(Date.now() + 10000).toISOString(),
  }), true);
  assert.equal(isRevenueCatEntitlementActive({
    expires_date: new Date(Date.now() - 10000).toISOString(),
  }), false);
});

test("all production product IDs have expected revenue values", () => {
  assert.equal(productRevenueCents.monthly, 999);
  assert.equal(productRevenueCents.tech_monthly, 199);
  assert.equal(productRevenueCents.college_monthly, 499);
  assert.equal(productRevenueCents.nurse_monthly, 1499);
  assert.equal(productRevenueCents["nurse_monthly:monthly"], 1499);
  assert.equal(productRevenueCents.doctor_monthly, 3999);
  assert.equal(productRevenueCents.video_minutes_400, 499);
  assert.equal(productRevenueCents.video_minutes_800, 999);
  assert.equal(productRevenueCents.video_minutes_2500, 1999);
});
