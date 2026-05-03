const String kGetHomeData = r'''
query GetHomeData {
  siteInfo {
    name tagline location phone email whatsapp
  }
  portfolio(featuredOnly: true, limit: 8) {
    id title slug mediaType imageUrl isFeature: isFeatured
  }
  services {
    id name slug tagline coverImageUrl
  }
  testimonials(limit: 4) {
    id name role message rating
  }
}
''';

const String kGetPortfolio = r'''
query GetPortfolio($category: String) {
  portfolio(category: $category, limit: 50) {
    id title slug mediaType imageUrl videoUrl description clientName location
  }
  categories {
    id name slug
  }
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
  products {
    id name slug description priceUsd priceMwk stock imageUrl
  }
}
''';

const String kGetBlog = r'''
query GetBlog {
  blogPosts(limit: 20) {
    id title slug excerpt publishedAt coverImageUrl
  }
}
''';

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
  ) {
    success message bookingId
  }
}
''';
