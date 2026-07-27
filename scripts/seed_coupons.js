/**
 * Coupons Seed Script
 * Seeds the 'coupons' collection with sample data across popular categories
 * for testing the Coupons Marketplace feature.
 *
 * Usage:
 *   cd scripts
 *   npm install
 *   node seed_coupons.js
 *
 * Prerequisites:
 *   - Either place service-account-key.json in the scripts/ directory
 *   - Or set GOOGLE_APPLICATION_CREDENTIALS env var pointing to your key file
 *   - Run `npm install` to install firebase-admin dependency
 */

const admin = require('firebase-admin');

// ─── Firebase Init ─────────────────────────────────────────────

let serviceAccount;
try {
  serviceAccount = require('./service-account-key.json');
} catch (e) {
  // Will use application default credentials instead
}

admin.initializeApp({
  credential: serviceAccount
    ? admin.credential.cert(serviceAccount)
    : admin.credential.applicationDefault(),
  projectId: process.env.GOOGLE_CLOUD_PROJECT || 'cashspark-c15bd',
});

const db = admin.firestore();

// ─── Helper ────────────────────────────────────────────────────

const now = admin.firestore.Timestamp.now();
const daysFromNow = (d) =>
  admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + d * 24 * 60 * 60 * 1000)
  );

// Placeholder images (reliable, free CDN-based placeholder service)
const img = (seed) =>
  `https://picsum.photos/seed/${seed}/200/200`;

// ─── Coupons Data ──────────────────────────────────────────────

const COUPONS = [
  // ── Amazon ───────────────────────────────────────────────
  {
    brandName: 'Amazon',
    category: 'Amazon',
    offerTitle: 'Up to 70% Off on Electronics',
    shortDescription: 'Exclusive deals on headphones, smartwatches & more',
    discountText: 'Min 50% Off',
    destinationUrl: 'https://www.amazon.in/deals?ref=cashspark_coupon',
    imageUrl: img('amazon_electronics'),
    isFeatured: true,
    sortOrder: 1,
  },
  {
    brandName: 'Amazon',
    category: 'Amazon',
    offerTitle: 'Flat 40% Off on Fashion',
    shortDescription: 'Top brands at unbeatable prices',
    discountText: 'Flat 40% Off',
    destinationUrl: 'https://www.amazon.in/fashion-deals?ref=cashspark_coupon',
    imageUrl: img('amazon_fashion'),
    isFeatured: false,
    sortOrder: 2,
  },
  {
    brandName: 'Amazon',
    category: 'Amazon',
    offerTitle: 'Get ₹150 Cashback on Prime',
    shortDescription: 'Special offer for new Prime members',
    discountText: '₹150 Cashback',
    destinationUrl: 'https://www.amazon.in/prime-offer?ref=cashspark_coupon',
    imageUrl: img('amazon_prime'),
    isFeatured: true,
    sortOrder: 3,
  },

  // ── Flipkart ────────────────────────────────────────────
  {
    brandName: 'Flipkart',
    category: 'Flipkart',
    offerTitle: 'Big Billion Days – Extra 30% Off',
    shortDescription: 'Massive savings on mobiles, electronics & more',
    discountText: 'Extra 30% Off',
    destinationUrl: 'https://www.flipkart.com/big-billion-days?ref=cashspark_coupon',
    imageUrl: img('flipkart_bbd'),
    isFeatured: true,
    sortOrder: 4,
  },
  {
    brandName: 'Flipkart',
    category: 'Flipkart',
    offerTitle: 'Buy 1 Get 1 Free on Home Appliances',
    shortDescription: 'Limited period BOGO on select items',
    discountText: 'BOGO Free',
    destinationUrl: 'https://www.flipkart.com/home-deals?ref=cashspark_coupon',
    imageUrl: img('flipkart_bogo'),
    isFeatured: false,
    sortOrder: 5,
  },
  {
    brandName: 'Flipkart',
    category: 'Flipkart',
    offerTitle: 'Flat 60% Off on Men\'s Footwear',
    shortDescription: 'Premium shoes at factory prices',
    discountText: 'Flat 60% Off',
    destinationUrl: 'https://www.flipkart.com/footwear?ref=cashspark_coupon',
    imageUrl: img('flipkart_footwear'),
    isFeatured: false,
    sortOrder: 6,
  },

  // ── Myntra ──────────────────────────────────────────────
  {
    brandName: 'Myntra',
    category: 'Myntra',
    offerTitle: 'End of Season Sale – Up to 80% Off',
    shortDescription: 'Trendy fashion from top brands at huge discounts',
    discountText: 'Up to 80% Off',
    destinationUrl: 'https://www.myntra.com/end-of-season?ref=cashspark_coupon',
    imageUrl: img('myntra_eos'),
    isFeatured: true,
    sortOrder: 7,
  },
  {
    brandName: 'Myntra',
    category: 'Myntra',
    offerTitle: 'Extra ₹500 Off on Orders Above ₹2999',
    shortDescription: 'Use code MYN500 at checkout',
    discountText: 'Extra ₹500 Off',
    destinationUrl: 'https://www.myntra.com/coupons?ref=cashspark_coupon',
    imageUrl: img('myntra_coupon'),
    isFeatured: false,
    sortOrder: 8,
  },

  // ── AJIO ────────────────────────────────────────────────
  {
    brandName: 'AJIO',
    category: 'AJIO',
    offerTitle: 'Everything Under ₹499',
    shortDescription: 'Massive stock clearance – all items under ₹499',
    discountText: 'Under ₹499',
    destinationUrl: 'https://www.ajio.com/clearance?ref=cashspark_coupon',
    imageUrl: img('ajio_clearance'),
    isFeatured: false,
    sortOrder: 9,
  },
  {
    brandName: 'AJIO',
    category: 'AJIO',
    offerTitle: 'Buy 3 Get 30% Off on Ethnic Wear',
    shortDescription: 'Festive collection at amazing discounts',
    discountText: 'Buy 3, Get 30% Off',
    destinationUrl: 'https://www.ajio.com/ethnic-collection?ref=cashspark_coupon',
    imageUrl: img('ajio_ethnic'),
    isFeatured: true,
    sortOrder: 10,
  },

  // ── Nykaa ───────────────────────────────────────────────
  {
    brandName: 'Nykaa',
    category: 'Nykaa',
    offerTitle: 'Pink Friday Sale – Up to 50% Off',
    shortDescription: 'Beauty, skincare & makeup at amazing prices',
    discountText: 'Up to 50% Off',
    destinationUrl: 'https://www.nykaa.com/pink-friday?ref=cashspark_coupon',
    imageUrl: img('nykaa_pink'),
    isFeatured: true,
    sortOrder: 11,
  },
  {
    brandName: 'Nykaa',
    category: 'Nykaa',
    offerTitle: 'Free Gift on Orders Above ₹999',
    shortDescription: 'Get a free beauty kit with every order',
    discountText: 'Free Gift Worth ₹299',
    destinationUrl: 'https://www.nykaa.com/offers?ref=cashspark_coupon',
    imageUrl: img('nykaa_gift'),
    isFeatured: false,
    sortOrder: 12,
  },

  // ── Electronics ─────────────────────────────────────────
  {
    brandName: 'boAt',
    category: 'Electronics',
    offerTitle: 'Flat 35% Off on Wireless Earbuds',
    shortDescription: 'Best-selling audio gear at lowest prices ever',
    discountText: 'Flat 35% Off',
    destinationUrl: 'https://www.boat-lifestyle.com/earbuds?ref=cashspark_coupon',
    imageUrl: img('boat_earbuds'),
    isFeatured: false,
    sortOrder: 13,
  },
  {
    brandName: 'Noise',
    category: 'Electronics',
    offerTitle: 'Buy Smartwatch at ₹1999 Only',
    shortDescription: 'Limited period flash sale on smart wearables',
    discountText: 'Just ₹1,999',
    destinationUrl: 'https://www.gonoise.com/smartwatch?ref=cashspark_coupon',
    imageUrl: img('noise_watch'),
    isFeatured: true,
    sortOrder: 14,
  },
  {
    brandName: 'Realme',
    category: 'Electronics',
    offerTitle: 'Extra ₹1000 Off on Realme Phones',
    shortDescription: 'Bank offer + exchange bonus available',
    discountText: 'Extra ₹1,000 Off',
    destinationUrl: 'https://www.realme.com/in/phones?ref=cashspark_coupon',
    imageUrl: img('realme_phones'),
    isFeatured: false,
    sortOrder: 15,
  },

  // ── Fashion ─────────────────────────────────────────────
  {
    brandName: 'H&M',
    category: 'Fashion',
    offerTitle: 'Member Exclusive – 25% Off Everything',
    shortDescription: 'Sign up free and get 25% off your first order',
    discountText: '25% Off Entire Order',
    destinationUrl: 'https://www2.hm.com/en_in/membership?ref=cashspark_coupon',
    imageUrl: img('hm_member'),
    isFeatured: false,
    sortOrder: 16,
  },
  {
    brandName: 'Zara',
    category: 'Fashion',
    offerTitle: 'Mid-Season Sale – Up to 50% Off',
    shortDescription: 'Trending styles at half the price',
    discountText: 'Up to 50% Off',
    destinationUrl: 'https://www.zara.com/in/sale?ref=cashspark_coupon',
    imageUrl: img('zara_sale'),
    isFeatured: true,
    sortOrder: 17,
  },

  // ── Beauty ──────────────────────────────────────────────
  {
    brandName: 'Maybelline',
    category: 'Beauty',
    offerTitle: 'Buy 2 Get 1 Free on Lipsticks',
    shortDescription: 'Shades for every skin tone',
    discountText: 'BOGO Free',
    destinationUrl: 'https://www.maybelline.co.uk/lips?ref=cashspark_coupon',
    imageUrl: img('maybelline_lips'),
    isFeatured: false,
    sortOrder: 18,
  },
  {
    brandName: 'Lakmé',
    category: 'Beauty',
    offerTitle: 'Flat 30% Off on Absolute Range',
    shortDescription: 'Premium makeup at affordable prices',
    discountText: 'Flat 30% Off',
    destinationUrl: 'https://www.lakmeindia.com/absolute?ref=cashspark_coupon',
    imageUrl: img('lakme_absolute'),
    isFeatured: false,
    sortOrder: 19,
  },

  // ── Food ────────────────────────────────────────────────
  {
    brandName: 'Zomato',
    category: 'Food',
    offerTitle: 'Flat ₹150 Off on Orders Above ₹499',
    shortDescription: 'Use code CASH150 at checkout',
    discountText: 'Flat ₹150 Off',
    destinationUrl: 'https://www.zomato.com/coupons?ref=cashspark_coupon',
    imageUrl: img('zomato_delivery'),
    isFeatured: true,
    sortOrder: 20,
  },
  {
    brandName: 'Swiggy',
    category: 'Food',
    offerTitle: 'Free Delivery + 20% Off on First Order',
    shortDescription: 'Welcome offer for all new users',
    discountText: 'Free Delivery + 20% Off',
    destinationUrl: 'https://www.swiggy.com/offers?ref=cashspark_coupon',
    imageUrl: img('swiggy_first'),
    isFeatured: false,
    sortOrder: 21,
  },
  {
    brandName: 'Domino\'s',
    category: 'Food',
    offerTitle: 'Buy 1 Large Pizza Get 1 Free',
    shortDescription: 'Everyday value offer for pizza lovers',
    discountText: 'BOGO Large Pizza',
    destinationUrl: 'https://www.dominos.co.in/deals?ref=cashspark_coupon',
    imageUrl: img('dominos_bogo'),
    isFeatured: false,
    sortOrder: 22,
  },

  // ── Travel ─────────────────────────────────────────────
  {
    brandName: 'MakeMyTrip',
    category: 'Travel',
    offerTitle: 'Flat ₹1,200 Off on Flight Bookings',
    shortDescription: 'Domestic flight deals for weekend getaways',
    discountText: 'Flat ₹1,200 Off',
    destinationUrl: 'https://www.makemytrip.com/flights?ref=cashspark_coupon',
    imageUrl: img('mmt_flights'),
    isFeatured: true,
    sortOrder: 23,
  },
  {
    brandName: 'OYO',
    category: 'Travel',
    offerTitle: '40% Off on Hotel Bookings',
    shortDescription: 'Stay at premium hotels at budget prices',
    discountText: '40% Off on Hotels',
    destinationUrl: 'https://www.oyorooms.com/coupons?ref=cashspark_coupon',
    imageUrl: img('oyo_hotels'),
    isFeatured: false,
    sortOrder: 24,
  },
  {
    brandName: 'Uber',
    category: 'Travel',
    offerTitle: 'Get 2 Free Rides Worth ₹250',
    shortDescription: 'Welcome offer for new Uber users',
    discountText: 'Free Rides Worth ₹250',
    destinationUrl: 'https://www.uber.com/in/promotions?ref=cashspark_coupon',
    imageUrl: img('uber_welcome'),
    isFeatured: true,
    sortOrder: 25,
  },

  // ── Expired coupon (for testing expiry filtering) ────
  {
    brandName: 'Amazon',
    category: 'Amazon',
    offerTitle: 'Flash Sale – Extra 10% Off',
    shortDescription: 'This offer has expired (test data)',
    discountText: 'Extra 10% Off',
    destinationUrl: 'https://www.amazon.in/flash-sale?ref=cashspark_coupon',
    imageUrl: img('amazon_flash'),
    isFeatured: false,
    expiryDate: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
    sortOrder: 99,
  },
  {
    brandName: 'Flipkart',
    category: 'Flipkart',
    offerTitle: 'Weekend Special – 15% Cashback',
    shortDescription: 'This offer has expired (test data)',
    discountText: '15% Cashback',
    destinationUrl: 'https://www.flipkart.com/weekend-special?ref=cashspark_coupon',
    imageUrl: img('flipkart_weekend'),
    isFeatured: false,
    expiryDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), // 5 days ago
    sortOrder: 100,
  },
];

// ─── Seed Function ─────────────────────────────────────────────

async function seedCoupons() {
  console.log('🎫 Seeding "coupons" collection...');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`Project: ${process.env.GOOGLE_CLOUD_PROJECT || 'cashspark-c15bd'}`);
  console.log('');

  const batch = db.batch();
  let count = 0;

  let idx = 0;
  for (const coupon of COUPONS) {
    const couponId =
      'cpn_' +
      coupon.brandName.toLowerCase().replace(/\s+/g, '_') +
      '_' +
      coupon.offerTitle
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_|_$/g, '') +
      '_' +
      Date.now() + '_' + (idx++);

    const ref = db.collection('coupons').doc(couponId);

    const data = {
      couponId,
      brandName: coupon.brandName,
      category: coupon.category,
      offerTitle: coupon.offerTitle,
      shortDescription: coupon.shortDescription || null,
      discountText: coupon.discountText,
      destinationUrl: coupon.destinationUrl,
      imageUrl: coupon.imageUrl,
      expiryDate: coupon.expiryDate
        ? admin.firestore.Timestamp.fromDate(coupon.expiryDate)
        : null,
      isFeatured: coupon.isFeatured ?? false,
      isActive: true,
      sortOrder: coupon.sortOrder,
      createdAt: now,
      updatedAt: now,
    };

    batch.set(ref, data);
    count++;

    const expiryLabel = data.expiryDate
      ? ` (expires ${coupon.expiryDate.toLocaleDateString()})`
      : ' (no expiry)';
    const featuredLabel = coupon.isFeatured ? ' ★ FEATURED' : '';
    console.log(
      `  📍 [${coupon.category}] ${coupon.brandName} – ${coupon.offerTitle}${featuredLabel}${expiryLabel}`
    );
  }

  await batch.commit();
  console.log(`\n✅ ${count} coupons written to "coupons" collection`);
  console.log('   Categories seeded: Amazon, Flipkart, Myntra, AJIO,');
  console.log('   Nykaa, Electronics, Fashion, Beauty, Food, Travel');
  console.log(`   Expired coupons: ${COUPONS.filter((c) => c.expiryDate).length}`);
  console.log(`   Featured coupons: ${COUPONS.filter((c) => c.isFeatured).length}`);
}

async function main() {
  console.log('🚀 Fun Pay — Coupons Seed Script');
  console.log('');

  try {
    await seedCoupons();
    console.log('\n🎉 Seeding complete! Open the Coupons Marketplace to see your coupons.');
  } catch (error) {
    console.error('\n❌ Seeding failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }

  process.exit(0);
}

main();
