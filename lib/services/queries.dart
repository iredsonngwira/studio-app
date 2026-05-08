// ── Public queries ────────────────────────────────────────────────────────────

const String kGetHomeData = r'''
query GetHomeData {
  siteInfo { name tagline location phone email whatsapp }
  portfolio(featuredOnly: true, limit: 8) {
    id title slug mediaType imageUrl isFeatured
  }
  services { id name slug tagline coverImageUrl }
  testimonials(limit: 4) { id name role message rating }
}
''';

const String kGetPortfolio = r'''
query GetPortfolio($category: String) {
  portfolio(category: $category, limit: 50) {
    id title slug mediaType imageUrl videoUrl description clientName location
    isLicensable licensePriceUsd
  }
  categories { id name slug }
}
''';

const String kGetServices = r'''
query GetServices {
  services {
    id name slug tagline description coverImageUrl
    packages { id name priceUsd priceMwk description features isPopular }
  }
}
''';

const String kGetShop = r'''
query GetShop {
  products { id name slug description priceUsd priceMwk stock imageUrl }
}
''';

const String kGetBlog = r'''
query GetBlog {
  blogPosts(limit: 20) { id title slug excerpt publishedAt coverImageUrl }
}
''';

const String kGetExplorerFeed = r'''
query GetExplorerFeed($limit: Int) {
  explorerFeed(limit: $limit) {
    id title slug caption mediaType location
    imageUrl videoUrl isLicensable licensePriceUsd views createdAt
  }
}
''';

const String kGetStockPhotos = r'''
query GetStockPhotos($search: String) {
  stockPhotos(search: $search, limit: 40) {
    id title slug imageUrl location licensePriceUsd mediaType
  }
}
''';

const String kGetBookedDates = r'''
query GetBookedDates {
  bookedDates
}
''';

// ── Authenticated queries ─────────────────────────────────────────────────────

const String kGetMyGalleries = r'''
query GetMyGalleries {
  myGalleries {
    id title description narrative fileCount expiresAt thumbnailUrl createdAt
    files { id url thumbnailUrl fileType filename }
  }
}
''';

const String kGetMyBookings = r'''
query GetMyBookings {
  myBookings {
    id status sessionDate location notes isPaid source serviceName
  }
}
''';

const String kGetMyTimeline = r'''
query GetMyTimeline {
  myTimeline {
    entryType date title subtitle thumbnailUrl refId
  }
}
''';

const String kGetMyFavorites = r'''
query GetMyFavorites {
  myFavoritePhotos { id url thumbnailUrl fileType filename }
}
''';

// ── Mutations ─────────────────────────────────────────────────────────────────

const String kCreateBooking = r'''
mutation CreateBooking(
  $serviceId: Int!
  $guestName: String!
  $guestEmail: String!
  $guestPhone: String!
  $sessionDate: String!
  $location: String
  $notes: String
) {
  createBooking(
    serviceId: $serviceId
    guestName: $guestName
    guestEmail: $guestEmail
    guestPhone: $guestPhone
    sessionDate: $sessionDate
    location: $location
    notes: $notes
  ) { success message bookingId }
}
''';

const String kPreShootStylist = r'''
mutation PreShootStylist($description: String!) {
  preShootStylist(description: $description) { advice }
}
''';

const String kSearchStockAI = r'''
mutation SearchStockAI($query: String!) {
  searchStockPhotosAi(query: $query) {
    aiSummary
    items { id title imageUrl licensePriceUsd location }
  }
}
''';

const String kToggleFavorite = r'''
mutation ToggleFavorite($photoId: Int!) {
  toggleFavoritePhoto(photoId: $photoId) { success message }
}
''';

const String kSendMemory = r'''
mutation SendMemory(
  $galleryId: Int!
  $photoId: Int!
  $recipientName: String!
  $personalMessage: String
) {
  sendMemory(
    galleryId: $galleryId
    photoId: $photoId
    recipientName: $recipientName
    personalMessage: $personalMessage
  ) { success message }
}
''';

const String kPurchaseGift = r'''
mutation PurchaseGift(
  $serviceId: Int!
  $buyerName: String!
  $buyerEmail: String!
  $recipientName: String!
  $recipientPhone: String
  $personalMessage: String
) {
  purchaseGiftSession(
    serviceId: $serviceId
    buyerName: $buyerName
    buyerEmail: $buyerEmail
    recipientName: $recipientName
    recipientPhone: $recipientPhone
    personalMessage: $personalMessage
  ) { success message code }
}
''';

const String kInitiateLicense = r'''
mutation InitiateLicense(
  $itemType: String!
  $itemId: Int!
  $licenseType: String!
  $buyerName: String!
  $buyerEmail: String!
) {
  initiateLicensePurchase(
    itemType: $itemType
    itemId: $itemId
    licenseType: $licenseType
    buyerName: $buyerName
    buyerEmail: $buyerEmail
  ) { success message purchaseId amountUsd paypalClientId }
}
''';
