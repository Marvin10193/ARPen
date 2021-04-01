# What is ARPen?

Ever wanted to 3d print a dock for your phone? Or maybe a coffee cup holder that can be attached next to your car dashboard? If so, you would have to measure the dimensions of your phone and dashboard, construct 3d models using CAD-like software, convert these models to appropriate format, and print them in 3d. As you can see, this is an arduous process.

ARPen is an [iOS app][8] that allows you to use a mobile pen to perform free-hand 3D modeling _directly in the real world_. The app uses the in-built iPhone camera to do the tracking. ARPen uses the ARKit framework to track a special 3D-printed pen, called ARPen, in 3D. Instructions to build this pen can be found *below*.  

This project is sponsored by the German Federal Ministry of Education and Research (BMBF) as part of their Open Photonics call (Personal Photonics, 13N14065).  

# Instructions

## 1. Building the ARPen
The ARPen was originally built around the "Read Bear Nano v2" chip. As this chip is not sold anymore we created a custom chip using the "RN4871". In the following we explain both setups.

### 1.1 Setup using the "RN4871"
You can 3D print the whole ARPen on your own. The 3d models can be found under the `Redesign` folder.  

1. Print the 3d models for the ARPen.
	* Choose one top half
	* Print the lower half
2. Insert three momentary switches or buttons into the holes in the ARPen as shown below and solder them to cables, which will be connected to a Bluetooth chip as described in the next step.
3. Build and program the custom chip for the ARPen. The process is documented [here][9] in chapter 3. This chip will also work within the 3d models from the "Red Bear Nano v2"-setup. The other way does not work, as the Red Bear is to wide to fit into the new models.
4. Print the marker sheet which corresponds to your chosen top half on an A4 paper using a normal 2D printer, cut out the individual marker codes (6x or 12x), and paste them around the printed box.
5. Connect the momentary buttons and lithium-ion battery (110 mAh, 3.5V, [link to a sample battery][6]) to the chip as shown below.
6. Place the chip and battery inside the shaft of the pen. _Remember_ to disconnect the battery after using ARPen for sketching or modeling!

### 1.2 Setup using the "Read Bear Nano v2"
You can 3D print the whole ARPen on your own. The 3d models can be found under the `ARPen 3d Models and Marker` folder.  

1. Print the 3d models for the ARPen.
	* If you are using a multi-material printer, which allows you to use more than one print material, print the following models
		* `Pen.stl` in black __or__ white color.
		* `Box_white.stl` in _white_ color and `Box_black.stl` in _black_ color. Note: These two models may need to be merged before printing using appropriate software.  
		* `Cap_white.stl` in _white_ color and `Cap_black.stl` in _black_ color. Note: These two models may need to be merged before printing using appropriate software.  
	* If you are using a single-material printer:
		* Print these models: `Pen.stl`, `Box.stl`, and `Cap.stl`.
		* Print `Sticker.pdf` on an A4 paper using a normal 2D printer, cut out the individual marker codes (6x), and paste them around the printed box.
2. Insert three momentary switches or buttons into the holes in the ARPen as shown below and solder them to cables, which will be connected to a Bluetooth chip as described in step 4.  
	![][image-1]
3. Glue the box to the pen.
4. Add the Arduino Sketch under `ARPen/Bluetooth Software` to a Bluetooth chip. We used [RedBear BLE Nano v2][1]. To add the Arduino Sketch to the RedBear BLE Nano v2, please follow the instructions [here][5].
	* _Note_: RedBear has been acquired by Particle Mesh and is currently not available for sale. It is expected to be available for purchase on the [Particle Mesh catalog][4] soon.
	* Make sure that the BLE chip is inserted into the loader as shown in below -- inserting it the other way would cause the BLE chip to heat up and won't allow you to load your Arduino Sketch to the BLE chip.
		![][image-3]
5. Connect the Bluetooth chip and lithium-ion battery (110 mAh, 3.5V, [link to a sample battery][6]) to the momentary buttons as shown below.<br>
	![][image-2] ![][image-4]
6. Place the chip and battery inside the box, and then glue the pen to the box. _Remember_ to disconnect the battery after using ARPen for sketching or modeling!

## 2. Using the iOS App
You can install [the ARPen iOS app][8] like every other iOS app. Developers can run the Xcode project in this repository like any other iOS project.   

----

# Interested in Contributing to ARPen?

Feel free to [submit pull requests][3], [create issues][2] and spread the word! Please have a look at our [developer guide][7].

[1]: https://redbear.cc/product/ble-nano-2.html "RedBear Nano v2"
[2]: https://github.com/i10/ARPen/issues/new "Add an issue"
[3]: https://github.com/i10/ARPen/compare
[4]: https://www.particle.io/mesh/ "Particle Mesh"
[5]: https://github.com/redbear/nRF5x/blob/master/nRF52832/docs/Arduino_Board_Package_Installation_Guide.md "Arduino Board Package Installation Guide"
[6]: https://www.sparkfun.com/products/13853 "Lithium-Ion Battery"
[7]: https://github.com/i10/ARPen/wiki/Developing-for-ARPen "Developing for ARPen"
[8]: https://hci.rwth-aachen.de/arpen-ios "The ARPen iOS App"
[9]: https://hci.rwth-aachen.de/publications/schaefer2020a.pdf "Redesigning ARPen"

[image-1]:	https://github.com/i10/ARPen/blob/master/Documentation/images/Buttons.JPG "Momentary Buttons"
[image-2]:	https://github.com/i10/ARPen/blob/master/Documentation/images/Bluetooth%20setup.png "Bluetooth Setup"
[image-3]:  https://github.com/i10/ARPen/blob/master/Documentation/images/BLE%20mount%20setup.png "BLE Mount Setup"
[image-4]:  https://github.com/i10/ARPen/blob/master/Documentation/images/Soldering_Setup.png "Soldering Setup"
