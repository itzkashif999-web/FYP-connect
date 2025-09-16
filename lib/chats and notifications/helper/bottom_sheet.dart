
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'pick_image.dart';
import '../controller/profile_controller.dart';

class BottomSheet1 extends GetxController {
  final PickImage pick = Get.find<PickImage>();
  final ProfileController controller = Get.find<ProfileController>();

  void showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(top: 2.h, bottom: 7.h),
          children: [
            Text(
              "Pick Profile Picture",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(2.w),
                    shape: const CircleBorder(),
                    elevation: 3,
                  ),
                  onPressed: () async {
                    await pick.pickAndSaveImage(ImageSource.gallery);

                    // 🔹 Retrieve the saved image path
                    String? savedImagePath = await pick.getSavedImagePath();
                    if (savedImagePath != null) {
                      await controller.updateProfileImage();
                    }
                    Get.back();
                  },
                  child: SizedBox(
                    width: 15.w,
                    height: 15.w,
                    child: Image.asset(
                      'images/add_image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(2.w),
                    shape: const CircleBorder(),
                    elevation: 3,
                  ),
                  onPressed: () async {
                    await pick.pickAndSaveImage(ImageSource.camera);

                    // 🔹 Retrieve the saved image path
                    String? savedImagePath = await pick.getSavedImagePath();
                    if (savedImagePath != null) {
                      await controller.updateProfileImage();
                    }
                    Get.back();
                  },
                  child: SizedBox(
                    width: 15.w,
                    height: 15.w,
                    child: Image.asset(
                      'images/camera.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
