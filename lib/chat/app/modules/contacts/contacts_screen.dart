import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'contacts_controller.dart';

class ContactsScreen extends GetView<ContactsController> {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final results = controller.searchResults;
              if (results.isEmpty) {
                return const Center(
                  child: Text('Search for users to start a conversation'),
                );
              }

              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final user = results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    onTap: () => controller.startConversation(user),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
