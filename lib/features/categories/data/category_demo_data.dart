import 'package:flutter/material.dart';

class HomestayListingDemo {
  final String id;
  final String name;
  final String location;
  final int priceLkr;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String description;

  const HomestayListingDemo({
    required this.id,
    required this.name,
    required this.location,
    required this.priceLkr,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.description,
  });
}

class EcoExperienceDemo {
  final String id;
  final String name;
  final String category; // 'Eco Stays' | 'Nature Experiences'
  final String location;
  final String ecoBadge;
  final String description;
  final String imageUrl;

  const EcoExperienceDemo({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.ecoBadge,
    required this.description,
    required this.imageUrl,
  });
}

class ActivityDemo {
  final String id;
  final String name;
  final String category; // 'Hiking' | 'Surfing' | 'Cycling' | 'Cultural Experiences'
  final String location;
  final String duration;
  final int priceLkr;
  final String description;
  final String imageUrl;

  const ActivityDemo({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.duration,
    required this.priceLkr,
    required this.description,
    required this.imageUrl,
  });
}

class LocalGuideDemo {
  final String id;
  final String name;
  final String region;
  final List<String> languages;
  final String experience;
  final double rating;
  final String bio;
  final String imageUrl;

  const LocalGuideDemo({
    required this.id,
    required this.name,
    required this.region,
    required this.languages,
    required this.experience,
    required this.rating,
    required this.bio,
    required this.imageUrl,
  });
}

class VehicleRentalDemo {
  final String id;
  final String name;
  final String category; // 'Cars' | 'Bikes' | 'Scooters'
  final String location;
  final int pricePerDayLkr;
  final String transmission;
  final String description;
  final String imageUrl;

  const VehicleRentalDemo({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.pricePerDayLkr,
    required this.transmission,
    required this.description,
    required this.imageUrl,
  });
}

class CategoryDemoData {
  static String formatLkr(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return 'LKR ${buf.toString()}';
  }

  static const List<HomestayListingDemo> homestays = [
    HomestayListingDemo(
      id: 'hs_1',
      name: 'Traditional Villa with garden',
      location: 'Jaffna',
      priceLkr: 12500,
      rating: 4.8,
      reviewCount: 128,
      imageUrl:
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
      description:
          'Quiet heritage villa surrounded by tropical palms and home-cooked northern Sri Lankan breakfast.',
    ),
    HomestayListingDemo(
      id: 'hs_2',
      name: 'Ella Mountain Homestay',
      location: 'Ella',
      priceLkr: 18000,
      rating: 4.9,
      reviewCount: 256,
      imageUrl:
          'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=600',
      description:
          'Panoramic hill-country balcony overlooking Ella Gap with freshly brewed Ceylon tea.',
    ),
    HomestayListingDemo(
      id: 'hs_3',
      name: 'Kandy Heritage Courtyard',
      location: 'Kandy',
      priceLkr: 9500,
      rating: 4.7,
      reviewCount: 94,
      imageUrl:
          'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
      description:
          'Warm family-run stay 10 minutes from Kandy Lake and Temple of the Tooth.',
    ),
    HomestayListingDemo(
      id: 'hs_4',
      name: 'Galle Fort Colonial Home',
      location: 'Galle',
      priceLkr: 22000,
      rating: 4.9,
      reviewCount: 184,
      imageUrl:
          'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=600',
      description:
          'Restored Dutch-era townhouse inside Galle Fort with shaded verandah and coastal breeze.',
    ),
  ];

  static const List<EcoExperienceDemo> ecoExperiences = [
    EcoExperienceDemo(
      id: 'eco_1',
      name: 'Knuckles Cloud Forest Eco Lodge',
      category: 'Eco Stays',
      location: 'Matale',
      ecoBadge: 'Solar Powered • Zero Plastic',
      description:
          'Off-grid bamboo cabins nestled near mist-covered trails in the Knuckles Conservation Forest.',
      imageUrl:
          'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=600',
    ),
    EcoExperienceDemo(
      id: 'eco_2',
      name: 'Sinharaja Rainforest Canopy Walk',
      category: 'Nature Experiences',
      location: 'Deniyaya',
      ecoBadge: 'UNESCO Biosphere • Local Naturalist',
      description:
          'Guided morning walk spotting endemic birds, waterfalls, and ancient dipterocarp trees.',
      imageUrl:
          'https://images.unsplash.com/photo-1546708973-b339540b5162?w=600',
    ),
    EcoExperienceDemo(
      id: 'eco_3',
      name: 'Madu River Mangrove Kayaking',
      category: 'Nature Experiences',
      location: 'Balapitiya',
      ecoBadge: 'Low-Impact Paddle • Community Run',
      description:
          'Silent morning kayak route through mangrove tunnels and cinnamon island gardens.',
      imageUrl:
          'https://images.unsplash.com/photo-1586861635167-e5223aadc9fe?w=600',
    ),
    EcoExperienceDemo(
      id: 'eco_4',
      name: 'Horton Plains Eco Retreat',
      category: 'Eco Stays',
      location: 'Nuwara Eliya',
      ecoBadge: 'Rainwater Harvested • Organic Farm',
      description:
          'Highland eco cottage serving farm-to-table produce close to World’s End trailhead.',
      imageUrl:
          'https://images.unsplash.com/photo-1588598198321-9735fd52455b?w=600',
    ),
  ];

  static const List<ActivityDemo> activities = [
    ActivityDemo(
      id: 'act_1',
      name: 'Ella Rock Sunrise Hike',
      category: 'Hiking',
      location: 'Ella',
      duration: '4 hours',
      priceLkr: 4500,
      description:
          'Guided dawn trek along railway tracks and tea slopes to Ella Rock summit.',
      imageUrl:
          'https://images.unsplash.com/photo-1546708973-b339540b5162?w=600',
    ),
    ActivityDemo(
      id: 'act_2',
      name: 'Weligama Beginner Surf Lesson',
      category: 'Surfing',
      location: 'Weligama',
      duration: '2 hours',
      priceLkr: 6000,
      description:
          'Gentle sandy-bottom beach break session with surfboard and certified instructor.',
      imageUrl:
          'https://images.unsplash.com/photo-1586861635167-e5223aadc9fe?w=600',
    ),
    ActivityDemo(
      id: 'act_3',
      name: 'Polonnaruwa Heritage Cycling',
      category: 'Cycling',
      location: 'Polonnaruwa',
      duration: '3 hours',
      priceLkr: 3800,
      description:
          'Cycle shaded paths across ancient stupas, royal pavilions, and Parakrama Samudra.',
      imageUrl:
          'https://images.unsplash.com/photo-1588598198321-9735fd52455b?w=600',
    ),
    ActivityDemo(
      id: 'act_4',
      name: 'Kandyan Drum & Craft Workshop',
      category: 'Cultural Experiences',
      location: 'Kandy',
      duration: '2.5 hours',
      priceLkr: 5200,
      description:
          'Hands-on cultural session with traditional Kandyan drummers and brass artisans.',
      imageUrl:
          'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=600',
    ),
  ];

  static const List<LocalGuideDemo> guides = [
    LocalGuideDemo(
      id: 'gd_1',
      name: 'Saman Perera',
      region: 'Kandy',
      languages: ['English', 'Sinhala'],
      experience: '8 years experience',
      rating: 4.9,
      bio:
          'Licensed cultural & heritage guide specializing in Temple of the Tooth and hill-country tea trails.',
      imageUrl: '',
    ),
    LocalGuideDemo(
      id: 'gd_2',
      name: 'Nirosha Selvam',
      region: 'Jaffna',
      languages: ['Tamil', 'English'],
      experience: '6 years experience',
      rating: 4.8,
      bio:
          'Northern peninsula specialist covering Nallur Kovil, Delft Island, and Jaffna culinary walks.',
      imageUrl: '',
    ),
    LocalGuideDemo(
      id: 'gd_3',
      name: 'Ruwan Jayawardena',
      region: 'Ella',
      languages: ['English', 'German', 'Sinhala'],
      experience: '10 years experience',
      rating: 4.9,
      bio:
          'Mountain trekker and nature guide for Ella Rock, Nine Arch Bridge, and Knuckles trails.',
      imageUrl: '',
    ),
    LocalGuideDemo(
      id: 'gd_4',
      name: 'Fathima Rizwan',
      region: 'Galle',
      languages: ['English', 'French'],
      experience: '5 years experience',
      rating: 4.7,
      bio:
          'Architectural walking-tour host inside Galle Fort and southern coastal artisan villages.',
      imageUrl: '',
    ),
  ];

  static const List<VehicleRentalDemo> rentals = [
    VehicleRentalDemo(
      id: 'rt_1',
      name: 'Suzuki Alto Compact Car',
      category: 'Cars',
      location: 'Colombo',
      pricePerDayLkr: 8500,
      transmission: 'Automatic • A/C',
      description:
          'Fuel-efficient compact hatchback ideal for coastal highways and city exploring.',
      imageUrl:
          'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600',
    ),
    VehicleRentalDemo(
      id: 'rt_2',
      name: 'Honda Dio 110cc Scooter',
      category: 'Scooters',
      location: 'Ella',
      pricePerDayLkr: 3200,
      transmission: 'Automatic • 2 Helmets',
      description:
          'Easy-to-ride scooter for hill-country viewpoints, waterfalls, and cafes.',
      imageUrl:
          'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=600',
    ),
    VehicleRentalDemo(
      id: 'rt_3',
      name: 'Mountain Trekking Bicycle',
      category: 'Bikes',
      location: 'Polonnaruwa',
      pricePerDayLkr: 1800,
      transmission: '21-Speed • Lock Included',
      description:
          'Lightweight alloy bicycle suited for ancient city ruins and village trails.',
      imageUrl:
          'https://images.unsplash.com/photo-1588598198321-9735fd52455b?w=600',
    ),
    VehicleRentalDemo(
      id: 'rt_4',
      name: 'Toyota Prius Hybrid',
      category: 'Cars',
      location: 'Kandy',
      pricePerDayLkr: 14000,
      transmission: 'Automatic • 5 Seats',
      description:
          'Spacious hybrid sedan with luggage room for multi-day island road trips.',
      imageUrl:
          'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
    ),
  ];
}

void showCategoryDemoNotice(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String description,
  IconData icon = Icons.info_outline_rounded,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0A4DF5), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF082B5C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A4DF5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Text(
              'Demo preview only: live booking, messaging, and payment contracts are not connected in this release.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A4DF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    ),
  );
}

