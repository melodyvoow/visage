import 'package:flutter/material.dart';
import 'component/visage_home_scratch_card.dart';

class VisageHomeView extends StatelessWidget {
  const VisageHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 타이틀
            const Text(
              'Your Color, Your Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),

            // 서브 텍스트
            const Text(
              'AI가 만드는 당신만의 컴카드',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 60),

            // 스크래치 카드 영역
            const VisageHomeScratchCard(),

            const SizedBox(height: 60),

            // CTA 버튼
            ElevatedButton(
              onPressed: () {
                // TODO: 입력 폼으로 이동
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                '나만의 컴카드 만들기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
