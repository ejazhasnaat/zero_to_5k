import 'package:flutter/material.dart';

class MainRunScreen extends StatelessWidget {
  const MainRunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = [
      "WEEK 1\nDAY 1",
      "WEEK 1\nDAY 2",
      "WEEK 1\nDAY 3",
      "WEEK 2\nDAY 1",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text('Z25K'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.workspace_premium_rounded, color: Colors.amber),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "DURATION: 30 MINUTES",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: "Brisk five-minute warmup walk.\n",
                    style: TextStyle(fontSize: 16),
                    children: [
                      TextSpan(
                        text:
                            "Then alternate 60 seconds of jogging and 90 seconds of walking for a total of 20 minutes.",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Image.asset(
              'assets/images/start.jpg', // ensure the file is copied here
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to workout tracking
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("START", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: index == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                              color: index == 0 ? Colors.black : Colors.grey,
                            ),
                          ),
                          if (index == 0)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              height: 4,
                              width: 40,
                              color: Colors.redAccent,
                            )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
