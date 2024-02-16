package com.example.aplicatiessc;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button celsiusButton = findViewById(R.id.celsiusButton);
        Button fahrenheitButton = findViewById(R.id.fahrenheitButton);
        Button bluetoothButton = findViewById(R.id.connectBluetoothButton);

        bluetoothButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MainActivity.this, BluetoothActivity.class);
                startActivity(intent);
            }
        });

        celsiusButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Start the Celsius interface activity
                Intent intent = new Intent(MainActivity.this, CelsiusActivity.class);
                startActivity(intent);
            }
        });

        fahrenheitButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                // Start the Celsius interface activity
                Intent intent = new Intent(MainActivity.this, FahrenheitActivity.class);
                startActivity(intent);
            }
        });


    }



}