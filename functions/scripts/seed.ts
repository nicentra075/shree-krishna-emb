/**
 * Seeds the Firestore EMULATOR (or, with care, the TEST project) with
 * Phase 1 baseline data: config docs, stats, counters, categories, designs,
 * and sample orders for the admin transaction/dashboard screens.
 *
 * Emulator:  FIRESTORE_EMULATOR_HOST=localhost:8080 npm run seed
 * Test proj: GOOGLE_APPLICATION_CREDENTIALS=<sa.json> npm run seed
 *
 * Idempotent: fixed doc ids are overwritten, generated ids use stable seeds.
 */
import { initializeApp } from "firebase-admin/app";
import { Timestamp, getFirestore } from "firebase-admin/firestore";

import { Collections, DesignStatus, Docs, OrderStatus, ProcessingStatus } from "../src/config/constants";
import { todayKey } from "../src/utils/dates";
import { computeOrderAmounts } from "../src/utils/money";

initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? "shree-krishna-emb" });
const db = getFirestore();

const FEE_PCT = 12;
const GST_PCT = 18;

function iso(daysAgo: number, hour = 10): string {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  date.setHours(hour, 0, 0, 0);
  return date.toISOString();
}

function keywords(parts: string[]): string[] {
  const tokens = parts
    .join(" ")
    .toLowerCase()
    .split(/[^a-z0-9ऀ-ॿ]+/)
    .filter((token) => token.length >= 2);
  return [...new Set(tokens)].slice(0, 30);
}

const categories = [
  { id: "cat-bridal-blouses", name: "Bridal Blouses", nameHi: "दुल्हन ब्लाउज", sortOrder: 1 },
  { id: "cat-floral-sarees", name: "Floral Sarees", nameHi: "फूलों वाली साड़ियाँ", sortOrder: 2 },
  { id: "cat-kids-ethnic", name: "Kids Ethnic", nameHi: "बच्चों के एथनिक", sortOrder: 3 },
];

const designSeeds = [
  { id: "design-001", title: "Royal Peacock Bridal Blouse", cat: 0, price: 49900, techniques: ["Zardosi", "Mirror Work"], trending: true },
  { id: "design-002", title: "Golden Mandala Tapestry", cat: 0, price: 39900, techniques: ["Aari"], trending: true },
  { id: "design-003", title: "Lotus Bloom Saree Border", cat: 1, price: 29900, techniques: ["Thread Embroidery"], trending: false },
  { id: "design-004", title: "Botanical Flora Pattern Set", cat: 1, price: 24900, techniques: ["Machine Embroidery"], trending: true },
  { id: "design-005", title: "Marigold Garland Motif", cat: 1, price: 19900, techniques: ["Aari", "Bead Work"], trending: false },
  { id: "design-006", title: "Little Krishna Kurta Motif", cat: 2, price: 14900, techniques: ["Applique"], trending: false },
  { id: "design-007", title: "Elephant Parade Border", cat: 2, price: 17900, techniques: ["Kantha"], trending: false },
  { id: "design-008", title: "Paisley Heritage Blouse Back", cat: 0, price: 44900, techniques: ["Zardosi", "Stone Work"], trending: false },
  { id: "design-009", title: "Jasmine Vine Pallu Spread", cat: 1, price: 34900, techniques: ["Chikankari"], trending: false },
  { id: "design-010", title: "Mirror Bloom Lehenga Panel", cat: 0, price: 59900, techniques: ["Mirror Work", "Sequin Work"], trending: true },
];

async function seed(): Promise<void> {
  const batch = db.batch();

  // ---- config/platform ----
  batch.set(db.collection(Collections.config).doc(Docs.configPlatform), {
    platformFeePercent: FEE_PCT,
    gstPercent: GST_PCT,
    razorpayKeyId: "rzp_test_REPLACE_ME",
    supportEmail: "support@shreekrishnaemb.example",
    invoicePrefix: "SKE",
    sellerName: "Shree Krishna Embroidery",
    sellerAddress: "Surat, Gujarat, India",
    sellerGstin: "24XXXXX0000X1Z5",
    updatedAt: iso(30),
    updatedBy: "seed-script",
  });

  // ---- config/homeFeed ----
  batch.set(db.collection(Collections.config).doc(Docs.configHomeFeed), {
    banners: [
      {
        id: "banner-admin-picks",
        imageUrl: "",
        title: "Admin Picks",
        targetType: "design",
        targetId: "design-001",
        sortOrder: 1,
        isActive: true,
      },
      {
        id: "banner-trending",
        imageUrl: "",
        title: "Trending This Week",
        targetType: "category",
        targetId: "cat-bridal-blouses",
        sortOrder: 2,
        isActive: true,
      },
    ],
    updatedAt: iso(7),
    updatedBy: "seed-script",
  });

  // ---- counters/invoices ----
  batch.set(db.collection(Collections.counters).doc(Docs.countersInvoices), {
    seq: 3,
    year: new Date().getFullYear(),
  });

  // ---- categories ----
  for (const category of categories) {
    batch.set(db.collection(Collections.categories).doc(category.id), {
      name: category.name,
      nameLower: category.name.toLowerCase(),
      nameHi: category.nameHi,
      iconUrl: null,
      sortOrder: category.sortOrder,
      status: "active",
      designCount: designSeeds.filter((d) => categories[d.cat].id === category.id).length,
      createdAt: iso(60),
      updatedAt: null,
    });
  }

  // ---- designs ----
  designSeeds.forEach((seedDesign, index) => {
    const category = categories[seedDesign.cat];
    batch.set(db.collection(Collections.designs).doc(seedDesign.id), {
      title: seedDesign.title,
      titleLower: seedDesign.title.toLowerCase(),
      keywords: keywords([seedDesign.title, category.name, ...seedDesign.techniques, "Silk"]),
      description: `${seedDesign.title} — hand-finished embroidery pattern with stitch-ready digital file.`,
      categoryId: category.id,
      categoryName: category.name,
      techniques: seedDesign.techniques,
      threadType: "Silk",
      estimatedTimeMinutes: 240 + index * 30,
      price: seedDesign.price,
      currency: "INR",
      previewUrl: null,
      thumbUrl: null,
      processingStatus: ProcessingStatus.ready,
      fileStoragePath: `designs/${seedDesign.id}/source/${seedDesign.id}.emb`,
      fileName: `${seedDesign.id}.emb`,
      fileFormat: "EMB",
      fileSizeBytes: 350000 + index * 1000,
      designFormats: ["EMB"],
      // Downloadable source file, revealed in the user app once the design is
      // owned. Placeholder URL for testing the owned-download flow.
      designFiles: [
        {
          format: "EMB",
          name: `${seedDesign.id}.emb`,
          url: `https://picsum.photos/seed/${seedDesign.id}-file/600/600`,
          path: `design_files/${seedDesign.id}.emb`,
          sizeBytes: 350000 + index * 1000,
        },
      ],
      status: DesignStatus.active,
      isTrending: seedDesign.trending,
      avgRating: 0,
      ratingCount: 0,
      ratingSum: 0,
      salesCount: 0,
      createdAt: iso(45 - index * 3),
      updatedAt: null,
      createdBy: "seed-script",
    });
  });

  // ---- sample orders (3 across statuses/dates) ----
  const orderSeeds = [
    { id: "order_seed_0001", design: designSeeds[0], status: OrderStatus.paid, daysAgo: 6, invoice: "SKE-2026-00001" },
    { id: "order_seed_0002", design: designSeeds[3], status: OrderStatus.paid, daysAgo: 2, invoice: "SKE-2026-00002" },
    { id: "order_seed_0003", design: designSeeds[9], status: OrderStatus.created, daysAgo: 0, invoice: null },
  ];

  let revenue = 0;
  let fees = 0;
  let gst = 0;
  let paidCount = 0;

  for (const order of orderSeeds) {
    const amounts = computeOrderAmounts(order.design.price, FEE_PCT, GST_PCT);
    const isPaid = order.status === OrderStatus.paid;
    if (isPaid) {
      revenue += amounts.totalAmount;
      fees += amounts.platformFee;
      gst += amounts.gstAmount;
      paidCount += 1;
    }
    const category = categories[order.design.cat];
    batch.set(db.collection(Collections.orders).doc(order.id), {
      userId: "seed-buyer-uid",
      buyerName: "Seed Buyer",
      buyerEmail: "buyer@example.com",
      items: [
        {
          designId: order.design.id,
          title: order.design.title,
          thumbUrl: null,
          price: order.design.price,
          fileFormat: "EMB",
          categoryId: category.id,
          categoryName: category.name,
        },
      ],
      itemsSubtotal: amounts.itemsSubtotal,
      platformFee: amounts.platformFee,
      gstAmount: amounts.gstAmount,
      totalAmount: amounts.totalAmount,
      platformFeePercent: FEE_PCT,
      gstPercent: GST_PCT,
      currency: "INR",
      status: order.status,
      razorpayPaymentId: isPaid ? `pay_seed_${order.id}` : null,
      invoiceNumber: order.invoice,
      refund: null,
      createdAt: iso(order.daysAgo, 11),
      paidAt: isPaid ? iso(order.daysAgo, 12) : null,
      refundedAt: null,
    });
  }

  // ---- stats/global + statsDaily for today ----
  batch.set(db.collection(Collections.stats).doc(Docs.statsGlobal), {
    totalUsers: 1,
    totalDesigners: 0,
    totalDesigns: designSeeds.length,
    totalOrders: paidCount,
    totalRevenue: revenue,
    totalPlatformFees: fees,
    pendingRefunds: 0,
    updatedAt: new Date().toISOString(),
  });

  batch.set(db.collection(Collections.statsDaily).doc(todayKey()), {
    date: todayKey(),
    newUsers: 0,
    ordersPaid: 0,
    revenue: 0,
    platformFees: 0,
    gst,
    refundsCount: 0,
    refundsAmount: 0,
  });

  // ---- activity ----
  const activityRef = db.collection(Collections.activity).doc("activity-seed-001");
  batch.set(activityRef, {
    type: "design_created",
    message: `Design "${designSeeds[0].title}" published`,
    refId: designSeeds[0].id,
    actorId: "seed-script",
    actorName: "Seed Script",
    metadata: {},
    createdAt: iso(1),
    expireAt: Timestamp.fromMillis(Date.now() + 30 * 24 * 60 * 60 * 1000),
  });

  await batch.commit();
  // eslint-disable-next-line no-console
  console.log(
    `Seeded: ${categories.length} categories, ${designSeeds.length} designs, ` +
      `${orderSeeds.length} orders, config + stats + counters.`,
  );
}

seed().then(
  () => process.exit(0),
  (error) => {
    // eslint-disable-next-line no-console
    console.error("Seed failed:", error);
    process.exit(1);
  },
);
