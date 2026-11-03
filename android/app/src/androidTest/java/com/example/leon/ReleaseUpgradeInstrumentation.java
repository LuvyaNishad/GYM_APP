package com.example.leon;

import android.app.Instrumentation;
import android.os.Bundle;
import android.util.Base64;
import java.io.File;
import java.io.FileInputStream;
import java.io.ByteArrayOutputStream;
import org.json.JSONObject;

/** Reads a stopped test installation's Hive files after a signed APK update. */
public final class ReleaseUpgradeInstrumentation extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle output = new Bundle();
        try {
            File directory = new File(getTargetContext().getApplicationInfo().dataDir, "app_flutter");
            JSONObject files = new JSONObject();
            String[] names = {"workouts", "user", "progress", "splits", "body_measurements", "custom_exercises", "settings"};
            for (String name : names) {
                File file = new File(directory, name + ".hive");
                if (!file.isFile()) throw new IllegalStateException("Missing Hive box: " + name);
                try (FileInputStream input = new FileInputStream(file); ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
                    byte[] buffer = new byte[4096];
                    int length;
                    while ((length = input.read(buffer)) != -1) bytes.write(buffer, 0, length);
                    files.put(file.getName(), Base64.encodeToString(bytes.toByteArray(), Base64.NO_WRAP));
                }
            }
            output.putString("hiveFiles", files.toString());
            finish(android.app.Activity.RESULT_OK, output);
        } catch (Exception error) {
            output.putString("failure", error.toString());
            finish(android.app.Activity.RESULT_CANCELED, output);
        }
    }
}
