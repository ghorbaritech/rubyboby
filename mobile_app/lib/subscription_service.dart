import 'package:flutter/material.dart';

enum SubscriptionTier { free, premium }

class SubscriptionService {
  static SubscriptionTier _currentTier = SubscriptionTier.free;

  static SubscriptionTier get currentTier => _currentTier;

  static bool get canAddMorePersonas {
    // Free tier limit: 2 personas
    // Premium: Unlimited
    if (_currentTier == SubscriptionTier.premium) return true;
    return false; // Logic to check current persona count against limit
  }

  static Future<void> upgradeToPremium(BuildContext context) async {
    // Mock Stripe / In-App Purchase Flow
    bool success = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Ruby Boby Premium'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.check, color: Colors.green),
              title: Text('Unlimited Custom Personas'),
            ),
            ListTile(
              leading: Icon(Icons.check, color: Colors.green),
              title: Text('Real-time Photo Lip-Sync'),
            ),
            ListTile(
              leading: Icon(Icons.check, color: Colors.green),
              title: Text('Advanced Learning Reports'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Maybe Later')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            child: const Text('Subscribe Now (\$9.99/mo)'),
          ),
        ],
      ),
    );

    if (success == true) {
      _currentTier = SubscriptionTier.premium;
    }
  }
}
