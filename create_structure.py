import os

# Define the structure
structure = {
    "lib": [
        "app.dart",
        "main.dart",
        "core/theme/app_colors.dart",
        "core/utils/constants.dart",
        "features/home/home_screen.dart",
        "features/home/home_controller.dart",
        "features/workouts/workout_editor_screen.dart",
        "features/workouts/workout_model.dart",
        "features/workouts/interval_model.dart",
        "features/workouts/workout_controller.dart",
        "features/tracking/tracking_service.dart",
        "features/audio/audio_coach.dart",
        "features/payments/stripe_service.dart",
        "features/reminders/reminder_service.dart",
        "features/dashboard/dashboard_screen.dart",
        "features/dashboard/progress_chart.dart",
        "models/user_preferences.dart",
        "services/local_storage_service.dart",
        "services/firebase_service.dart",
        "services/notification_service.dart",
        "providers/global_providers.dart",
    ]
}

def create_structure(base_path, structure):
    for folder, files in structure.items():
        for file_path in files:
            full_path = os.path.join(base_path, folder, file_path)
            dir_path = os.path.dirname(full_path)
            os.makedirs(dir_path, exist_ok=True)

            if not os.path.exists(full_path):
                with open(full_path, 'w') as f:
                    f.write(f"// TODO: Implement {file_path.split('/')[-1]}\n")
                print(f"✅ Created: {full_path}")
            else:
                print(f"⏭️ Skipped (exists): {full_path}")

if __name__ == "__main__":
    base_project_path = os.getcwd()
    create_structure(base_project_path, structure)
