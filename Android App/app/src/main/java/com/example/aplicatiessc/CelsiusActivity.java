package com.example.aplicatiessc;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class CelsiusActivity extends AppCompatActivity {


    private String bluetoothData = "";
    private TextView celsiusTextView;
    private final BroadcastReceiver bluetoothReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if ("com.example.aplicatiessc.ACTION_DATA_RECEIVED".equals(action)) {
                bluetoothData = intent.getStringExtra("DATA");
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        celsiusTextView.setText(bluetoothData + "°C");
                    }
                });
                Log.d("BluetoothData", "Received data: " + bluetoothData);
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.celsius);

        celsiusTextView = findViewById(R.id.celsiusResultTextView); // Initialize here
        Button backToMainC = findViewById(R.id.buttonBackCelsius);

        backToMainC.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Start the Celsius interface activity
                Intent intent = new Intent(CelsiusActivity.this, MainActivity.class);
                startActivity(intent);
            }
        });

    }

    @Override
    protected void onResume() {
        super.onResume();
        IntentFilter filter = new IntentFilter("com.example.aplicatiessc.ACTION_DATA_RECEIVED");
        registerReceiver(bluetoothReceiver, filter);
    }

    @Override
    protected void onPause() {
        super.onPause();
        unregisterReceiver(bluetoothReceiver);
    }
}
