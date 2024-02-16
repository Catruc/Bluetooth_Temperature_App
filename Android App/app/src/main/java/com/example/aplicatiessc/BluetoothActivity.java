package com.example.aplicatiessc;

import android.Manifest;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.annotation.Nullable;
import android.support.v4.app.ActivityCompat;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.*;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;


public class BluetoothActivity extends AppCompatActivity {


    private interface MessageConstants {
        int MESSAGE_READ = 0;
        int MESSAGE_WRITE = 1;
        int MESSAGE_TOAST = 2;
        // Add other message types here as needed.
    }

    private static final int REQUEST_ENABLE_BLUETOOTH = 0;
    private static final int REQUEST_DISCOVER_BLUETOOTH = 1;

    private String latestReceivedData = "";

    Button startButton, stopBluetooth, findDevices, connectDevices, showPaired;
    TextView statusBluetooth;

    ListView pairedDevices;

    ArrayAdapter<String> pairedDevicesAdapter;
    List<String> pairedDevicesList;
    BluetoothAdapter bluetoothAdapter;
    BluetoothServerSocket mmServerSocket;


    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(Message msg) {
            if (msg.what == MessageConstants.MESSAGE_READ) {
                String readMessage = new String((byte[]) msg.obj);
                Intent intent = new Intent("com.example.aplicatiessc.ACTION_DATA_RECEIVED");
                intent.putExtra("DATA", readMessage);
                sendBroadcast(intent);
            }
            return true;
        }
    });

    // Implement a method to check if the data is valid
    private boolean isValidData(String data) {
        // Your existing validation logic
        return data.matches("-?\\d+(\\.\\d+)?");
    }



    private class ConnectedThread extends Thread {
        private BluetoothSocket mmSocket;
        private InputStream mmInStream;
        private OutputStream mmOutStream;

        public ConnectedThread(BluetoothSocket socket) {
            mmSocket = socket;
            InputStream tmpIn = null;
            OutputStream tmpOut = null;

            try {
                tmpIn = socket.getInputStream();
                tmpOut = socket.getOutputStream();
            } catch (IOException e) {
                e.printStackTrace();
            }

            mmInStream = tmpIn;
            mmOutStream = tmpOut;
        }

        private final StringBuilder completeMessage = new StringBuilder();

        public void run() {
            byte[] buffer = new byte[1024];
            int bytes;

            while (true) {
                try {
                    bytes = mmInStream.read(buffer);
                    String receivedData = new String(buffer, 0, bytes);

                    // Accumulate the pieces of the message
                    completeMessage.append(receivedData);

                    // Assume that each message ends with a newline character
                    int endOfMessageIndex = completeMessage.indexOf("\n");
                    if (endOfMessageIndex != -1) {
                        // Extract the complete message up to the newline character
                        String fullMessage = completeMessage.substring(0, endOfMessageIndex).trim();
                        completeMessage.delete(0, endOfMessageIndex + 1);

                        if (isValidData(fullMessage)) {
                            latestReceivedData = fullMessage;

                            handler.obtainMessage(MessageConstants.MESSAGE_READ, -1, -1, fullMessage.getBytes())
                                    .sendToTarget();
                        }
                    }
                } catch (IOException e) {

                    break;
                }
            }
        }
    }


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.bluetooth);

        pairedDevices = findViewById(R.id.pairedDevicesListView);
        pairedDevicesList = new ArrayList<>();
        pairedDevicesAdapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, pairedDevicesList);
        pairedDevices.setAdapter(pairedDevicesAdapter);
        statusBluetooth = findViewById(R.id.statusBluetooth);
        startButton = findViewById(R.id.startBluetooth);
        stopBluetooth = findViewById(R.id.stopBluetooth);
        findDevices = findViewById(R.id.findDevices);
        showPaired = findViewById(R.id.showPaired);
        //connectDevices = findViewById(R.id.connectDevice);

        //adapter
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();




        // check bluetooth availability
        if (bluetoothAdapter == null) {
            statusBluetooth.setText("BLUETOOTH NOT AVAILABLE");
        } else {
            statusBluetooth.setText("BLUETOOTH IS AVAILABLE");
        }

        ///bluetooth on button

        startButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!bluetoothAdapter.isEnabled()) {
                    showToast("Turning on Bluetooth...");
                    //intent to on bluetooth
                    Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
                    startActivityForResult(intent, REQUEST_ENABLE_BLUETOOTH);
                } else {
                    showToast("Bluetooth is already on...");
                }
            }
        });

        //discover bluetooth button

        findDevices.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!bluetoothAdapter.isDiscovering()) {
                    showToast("Making device discoverable");
                    Intent intent = new Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE);
                    startActivityForResult(intent,REQUEST_DISCOVER_BLUETOOTH);
                }

            }
        });

        // bluetooth off button

        stopBluetooth.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(bluetoothAdapter.isEnabled())
                {
                    bluetoothAdapter.disable();
                    showToast("Turning off bluetooth");
                }else {
                    showToast("Bluetooth already off");
                }
            }
        });

        showPaired.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(bluetoothAdapter.isEnabled())
                {
                    pairedDevicesList.clear();
                    Set<BluetoothDevice> devices = bluetoothAdapter.getBondedDevices();
                    for(BluetoothDevice device: devices)
                    {
                        pairedDevicesList.add("\n Device" + device.getName() + " " + device.getAddress());
                    }pairedDevicesAdapter.notifyDataSetChanged();
                }
                else{
                    showToast("Turn on bluetooth");
                }
            }
        });

        // Set an item click listener for the list view
        pairedDevices.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                String deviceInfo = pairedDevicesList.get(position);
                String deviceAddress = deviceInfo.substring(deviceInfo.length() - 17);
                connectToDevice(deviceAddress);
            }
        });

    }


    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        switch(requestCode)
        {
            case REQUEST_ENABLE_BLUETOOTH:
                if (resultCode == RESULT_OK)
                {
                    //bluetooth is on
                    showToast("BLUETOOTH IS ON");
                }
                else{
                    //user denied
                    showToast("COULD NOT OPEN BLUETOOTH");
                }
                break;
        }
        super.onActivityResult(requestCode,resultCode,data);
    }


    // toast message function

    private void showToast(String msg){
        Toast.makeText(this, msg,Toast.LENGTH_SHORT).show();
    }

    private void connectToDevice(String deviceAddress) {
        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(deviceAddress);
        BluetoothSocket bluetoothSocket = null;

        // UUID should match the UUID that the server device is listening on.
        UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"); // Standard SerialPortService ID

        try {
            showToast("Connecting to device...");
            bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid);
            bluetoothSocket.connect();
            showToast("Connected to " + device.getName());

            ConnectedThread connectedThread = new ConnectedThread(bluetoothSocket);
            connectedThread.start();
            // You can now use the socket to communicate with the device
        } catch (IOException e) {
            showToast("Connection failed: " + e.getMessage());
            try {
                if (bluetoothSocket != null) {
                    bluetoothSocket.close();
                }
            } catch (IOException ex) {
                showToast("Socket close failed: " + ex.getMessage());
            }
        }
    }





}
