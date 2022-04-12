// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs2 is IHardwareSVGs, ICategories {
	function hardware_6() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Compass',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="translate(16335 16387) rotate(180)" gradientUnits="userSpaceOnUse" id="h6-a" x1="16334.5" x2="16334.5" y1="16384" y2="16387"><stop offset="0" stop-color="#818181"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-b" x1="15.9" x2="15.9" xlink:href="#h6-a" y1="61.38" y2="0.46"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-c" x1="15.98" x2="15.98" xlink:href="#h6-a" y1="62.03" y2="0"/><linearGradient gradientUnits="userSpaceOnUse" id="h6-d" x1="2" x2="2" y1="25.23" y2="23.23"><stop offset="0" stop-color="#818181"/><stop offset="0.2" stop-color="#4c4c4c"/><stop offset="0.8" stop-color="#fff"/><stop offset="1" stop-color="#818181"/></linearGradient><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-e" x1="13.6" x2="13.6" xlink:href="#h6-a" y1="53.73" y2="0.46"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-f" x1="13.6" x2="13.6" xlink:href="#h6-a" y1="0.27" y2="53.92"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-g" x1="5" x2="5" xlink:href="#h6-a" y1="51.23" y2="57.23"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-h" x1="5" x2="5" xlink:href="#h6-a" y1="57.73" y2="50.73"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-i" x1="17.77" x2="17.77" xlink:href="#h6-a" y1="22.51" y2="25.95"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-j" x1="17.77" x2="17.77" xlink:href="#h6-a" y1="26.45" y2="22.01"/><filter id="h6-k" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientUnits="userSpaceOnUse" id="h6-l" x1="110" x2="110" y1="131.5" y2="132.5"><stop offset="0" stop-color="#818181"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="#818181"/></linearGradient><linearGradient id="h6-m" x1="110" x2="110" xlink:href="#h6-d" y1="142" y2="122"/><linearGradient id="h6-n" x1="110" x2="110" xlink:href="#h6-d" y1="122.5" y2="142"/><linearGradient id="h6-o" x1="112" x2="108" xlink:href="#h6-d" y1="88.63" y2="88.63"/><linearGradient id="h6-p" x1="108" x2="112" xlink:href="#h6-l" y1="85.63" y2="85.63"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-q" x1="103.97" x2="116.03" xlink:href="#h6-a" y1="108.03" y2="95.97"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-r" x1="110" x2="110" xlink:href="#h6-a" y1="94.46" y2="109.54"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-s" x1="110" x2="110" xlink:href="#h6-a" y1="107" y2="112"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h6-t" x1="110" x2="110" xlink:href="#h6-a" y1="112.5" y2="106.5"/><symbol id="h6-v" viewBox="0 0 1 3"><line fill="none" stroke="url(#h6-a)" x1="0.5" x2="0.5" y1="3"/></symbol><symbol id="h6-u" viewBox="0 0 25.51 3.17"><use height="3" transform="matrix(0.5, 0, 0.18, 1, 0.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 1.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 2.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 3.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 4.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 5.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 6.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 7.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 8.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 9.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 10.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 11.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 12.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 13.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 14.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 15.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 16.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 17.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 18.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 19.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 20.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 21.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 22.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 23.24, 0.09)" width="1" xlink:href="#h6-v"/><use height="3" transform="matrix(0.5, 0, 0.18, 1, 24.24, 0.09)" width="1" xlink:href="#h6-v"/></symbol><symbol id="h6-bu" viewBox="0 0 29.96 66.27"><polyline fill="#fff" points="5 60.35 2.54 66.27 2.54 59.18"/><polyline fill="url(#h6-b)" points="24.69 0.46 29.31 2.38 4.73 61.38 2.5 60.45 2.5 53.73" stroke="url(#h6-c)"/><rect fill="url(#h6-d)" height="2" width="4" y="23.23"/><line fill="url(#h6-e)" stroke="url(#h6-f)" x1="2.5" x2="24.69" y1="53.73" y2="0.46"/><circle cx="5" cy="56.23" fill="#231f20" r="3"/><circle cx="5" cy="54.23" fill="url(#h6-g)" r="3" stroke="url(#h6-h)"/><circle cx="17.77" cy="24.23" fill="url(#h6-i)" r="1.72" stroke="url(#h6-j)"/></symbol></defs><g filter="url(#h6-k)"><rect fill="url(#h6-l)" height="1" width="56" x="82" y="131.5"/><use height="3.17" transform="translate(84.24 131.21) scale(1 0.5)" width="25.51" xlink:href="#h6-u"/><use height="3.17" transform="translate(135.76 132.79) rotate(180) scale(1 0.5)" width="25.51" xlink:href="#h6-u"/><use height="66.27" transform="translate(80 107.77)" width="29.96" xlink:href="#h6-bu"/><rect fill="url(#h6-m)" height="20" width="4" x="108" y="122"/><path d="M108,122.75h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4m-4,1h4" fill="none" stroke="url(#h6-n)" stroke-width="0.5"/><use height="66.27" transform="matrix(-1, 0, 0, 1, 140, 107.77)" width="29.96" xlink:href="#h6-bu"/><path d="M111,97.13h-2v-5h2Zm-3-17v8h4v-8Z" fill="url(#h6-o)"/><path d="M112,88.13l-1,4h-2l-1-4Zm-1-9h-2l-1,1h4Z" fill="url(#h6-p)"/><circle cx="110" cy="102" fill="none" r="8" stroke="url(#h6-q)" stroke-width="1.07"/><circle cx="110" cy="102" fill="none" r="7" stroke="url(#h6-r)" stroke-width="1.08"/><circle cx="110" cy="109.5" fill="url(#h6-s)" r="2.5" stroke="url(#h6-t)"/></g>'
					)
				)
			);
	}

	function hardware_7() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Gear',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient id="h7-a" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h7-b" x1="0" x2="0" xlink:href="#h7-a" y1="1" y2="0"/><linearGradient id="h7-c" x1="0" x2="1" xlink:href="#h7-a" y1="0" y2="0"/><linearGradient id="h7-d" x1="0" x2="0" xlink:href="#h7-a" y1="0" y2="1"/><symbol id="h7-g" viewBox="0 0 21.98 21.98"><path d="m0 0 1.39 1.08v13.18l-1.39.2Z" fill="url(#h7-b)"/><path d="m22 22-1.68-1.4A23.6 23.6 0 0 0 1.39 1.67L0 0a26.59 26.59 0 0 1 22 22Z" fill="url(#h7-b)"/><path d="m7.53 22 .25-1.38h13.07L22 22Z" fill="url(#h7-c)"/><path d="m0 14.46 1.39-.79a12 12 0 0 1 6.92 6.93L7.53 22A12.54 12.54 0 0 0 0 14.46Z" fill="url(#h7-c)"/></symbol><symbol id="h7-e" viewBox="0 0 9.97 7.84"><path d="M1.29 3.92V0l1.13.99v3.24L.3 7.84 0 6.12l1.29-2.2z" fill="url(#h7-b)"/><path d="M8.68 3.92V0L7.54.99v3.24l2.12 3.61.31-1.72-1.29-2.2z" fill="url(#h7-d)"/></symbol><symbol id="h7-h" viewBox="0 0 68.9 34.35"><use height="7.84" transform="translate(29.48)" width="9.97" xlink:href="#h7-e"/><use height="7.84" transform="rotate(-20 19.7 -49.24)" width="9.97" xlink:href="#h7-e"/><use height="7.84" transform="rotate(-40 19.71 -6.16)" width="9.97" xlink:href="#h7-e"/><use height="7.84" transform="matrix(.5 -.87 .87 .5 2.23 21.47)" width="9.97" xlink:href="#h7-e"/><use height="7.84" transform="rotate(-80 19.71 16.77)" width="9.97" xlink:href="#h7-e"/><use height="7.84" transform="rotate(80 19.71 51.9)" width="9.97" xlink:href="#h7-e"/><use height="7.84" transform="matrix(.5 .87 -.87 .5 61.7 12.86)" width="9.97" xlink:href="#h7-e"/><use height="7.84" transform="rotate(40 19.7 74.83)" width="9.97" xlink:href="#h7-e"/><use height="7.84" transform="rotate(20 19.71 117.92)" width="9.97" xlink:href="#h7-e"/></symbol><filter id="h7-f"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h7-f)"><path d="M106.81 165.8h6.39v-3.56l1.64-2.81 2.51 2.08 1.21 3.34 6-2.19-1.22-3.34.59-3.2 3.06 1.09 2.29 2.73 4.89-4.11-2.28-2.72-.55-3.21h3.25l3.09 1.78 3.19-5.54-3.08-1.78-1.6-2.82 3-1.14 3.51.62 1.1-6.29-3.5-.62-2.42-2.11 2.47-2.1 3.5-.62-1.1-6.3-3.51.62-3-1.13 1.6-2.83 3.08-1.78-3.19-5.53-3.09 1.78h-3.25l.55-3.2 2.28-2.73-4.89-4.1-2.33 2.67-3.06 1.09-.59-3.2 1.22-3.34-6-2.18-1.21 3.34-2.51 2.07-1.64-2.8v-3.56h-6.39v3.56l-1.65 2.8-2.51-2.07-1.21-3.34-6 2.18 1.22 3.34-.59 3.2-3.08-1.09-2.29-2.75-4.89 4.1 2.28 2.73.55 3.2H85.4l-3.09-1.78-3.19 5.53 3.08 1.78 1.61 2.83-3 1.13-3.5-.62-1.11 6.3 3.5.62 2.47 2.1-2.47 2.11-3.5.62 1.06 6.35 3.5-.62 3 1.14-1.61 2.82-3.08 1.78 3.19 5.54 3.09-1.78h3.25l-.55 3.21-2.28 2.72 4.89 4.11 2.34-2.71 3.06-1.09.59 3.2-1.22 3.34 6 2.19 1.21-3.34 2.51-2.08 1.65 2.81Zm-.46-57.8v13.2a12.26 12.26 0 0 0-7.12 7.12H86c2.21-10.74 9.58-18.1 20.35-20.32Zm0 47.94c-10.77-2.19-18.13-9.55-20.32-20.33h13.2a12.24 12.24 0 0 0 7.12 7.13Zm3.65-19.02a4.92 4.92 0 1 1 4.92-4.92 4.93 4.93 0 0 1-4.92 4.92Zm3.65 19.08v-13.2a12.24 12.24 0 0 0 7.12-7.13H134c-2.22 10.75-9.58 18.11-20.35 20.33Zm7.12-27.62a12.23 12.23 0 0 0-7.12-7.12V108c10.77 2.19 18.13 9.55 20.32 20.32Z" fill="url(#h7-d)" stroke="url(#h7-b)" stroke-miterlimit="10"/><use height="21.98" transform="translate(112.9 107.12)" width="21.98" xlink:href="#h7-g"/><use height="21.98" transform="rotate(90 -.01 134.89)" width="21.98" xlink:href="#h7-g"/><use height="21.98" transform="matrix(-1 0 0 1 107.1 107.12)" width="21.98" xlink:href="#h7-g"/><use height="21.98" transform="matrix(0 1 1 0 85.12 134.9)" width="21.98" xlink:href="#h7-g"/><use height="34.35" transform="translate(75.54 97.67)" width="68.9" xlink:href="#h7-h"/><use height="34.35" transform="rotate(180 72.23 83.17)" width="68.9" xlink:href="#h7-h"/><path d="M110 136.92a4.92 4.92 0 1 1 4.92-4.92 4.93 4.93 0 0 1-4.92 4.92Z" fill="none" stroke="url(#h7-d)" stroke-miterlimit="10" stroke-width="2"/><use height="34.35" transform="translate(75.54 97.67)" width="68.9" xlink:href="#h7-h"/><use height="34.35" transform="rotate(180 72.23 83.17)" width="68.9" xlink:href="#h7-h"/></g>'
					)
				)
			);
	}

	function hardware_8() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Tongs',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h8-b" x1="9.61" x2="19.45" y1="20.71" y2="73.46"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h8-c" x1="12.2" x2="12.2" y1="86.38" y2=".03"><stop offset="0" stop-color="#4b4b4b"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h8-d" x1="9.14" x2="9.14" y1=".03" y2="86.41"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16470.41)" gradientUnits="userSpaceOnUse" id="h8-a" x1="8.38" x2="0" y1="16469.9" y2="16469.9"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h8-e" x1="0" x2="0" xlink:href="#h8-a" y1="16466.39" y2="16470.41"/><linearGradient id="h8-f" x1="17.32" x2="24.41" xlink:href="#h8-a" y1="16384.52" y2="16384.52"/><linearGradient id="h8-i" x1="0" x2="0" y1="1" y2="0"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><symbol id="h8-h" viewBox="0 0 24.41 86.41"><path d="M17.66 85.88 15.4 79.9a3.26 3.26 0 0 1-.31-1.38V36.96a4.28 4.28 0 0 0-1.26-3.05L1.48 21.59a3.25 3.25 0 0 1-.95-2.29V.53h7.32V3.8l-1.3 1.3v11a4.28 4.28 0 0 0 1.26 3.04L19.85 31.2a3.27 3.27 0 0 1 .95 2.29v43.87a4.35 4.35 0 0 0 .26 1.48l2.59 7.05Z" fill="url(#h8-b)" stroke="url(#h8-c)" stroke-miterlimit="10"/><path d="M17.77 86.23 15.4 79.9a3.26 3.26 0 0 1-.31-1.37V36.96a4.28 4.28 0 0 0-1.26-3.05L1.48 21.59a3.25 3.25 0 0 1-.95-2.29V.03" fill="none" stroke="url(#h8-d)" stroke-miterlimit="10"/><path d="M1.03 1.03 0 0h8.38L7.35 1.03Z" fill="url(#h8-a)"/><path d="M7.35 1.03 8.38 0v4.02l-1.03-.43Z" fill="url(#h8-e)"/><path d="m22.93 85.38 1.48 1.03h-7.09l.66-1.03Z" fill="url(#h8-f)"/></symbol><filter id="h8-g"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h8-g)"><use height="86.41" transform="translate(99.39 88.66)" width="24.41" xlink:href="#h8-h"/><path d="m111.29 121.36.25-1.15 3.67-3.67 1.3-.13-1.56-1.58-5.63 4.87Z"/><use height="86.41" transform="matrix(-1 0 0 1 120.61 88.66)" width="24.41" xlink:href="#h8-h"/><path d="M110 117.05a2.16 2.16 0 1 0-2.16-2.16 2.16 2.16 0 0 0 2.16 2.16Z" fill="url(#h8-i)"/><path d="M110 115.63a.75.75 0 1 0-.75-.74.75.75 0 0 0 .75.74Z"/></g>'
					)
				)
			);
	}

	function hardware_9() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Compass and Triangle',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h9-a" x1="18.26" x2="13.81" y1="41.36" y2="12.08"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h9-b" x1="6.1" x2="20.82" xlink:href="#h9-a" y1="19.57" y2="32.95"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 16440.35)" id="h9-c" x1="24.51" x2="24.51" xlink:href="#h9-a" y1="16396.45" y2="16384"/><linearGradient id="h9-d" x1=".06" x2="8.6" xlink:href="#h9-a" y1="-10.72" y2="13.85"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h9-f" x1="110" x2="110" xlink:href="#h9-a" y1="98.4" y2="139.28"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h9-g" x1="84.21" x2="135.79" y1="132.52" y2="132.52"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h9-h" x1="122.69" x2="122.69" xlink:href="#h9-a" y1="107.24" y2="133.03"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" gradientUnits="userSpaceOnUse" id="h9-i" x1="67.83" x2="152.17" y1="139.3" y2="139.3"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h9-j" x1="97.1" x2="97.1" xlink:href="#h9-a" y1="133.03" y2="107.24"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h9-k" x1="131.09" x2="131.09" xlink:href="#h9-a" y1="139.82" y2="97.65"/><linearGradient gradientTransform="matrix(1 0 0 -1 0 264)" id="h9-l" x1="88.91" x2="88.91" xlink:href="#h9-a" y1="97.65" y2="139.82"/><linearGradient id="h9-n" x1="110" x2="110" xlink:href="#h9-a" y1="108.09" y2="95.9"/><linearGradient id="h9-o" x1="110" x2="110" xlink:href="#h9-a" y1="95.4" y2="108.59"/><linearGradient id="h9-p" x1="110" x2="110" xlink:href="#h9-a" y1="98.38" y2="105.62"/><symbol id="h9-m" viewBox="0 0 27.97 56.35"><path d="m17.34 35.66 3 8.39-1.68 1.39-3-8ZM6.72 22.17a3.08 3.08 0 0 0 1.61 1.75l1.72.77a3.06 3.06 0 0 1 1.59 1.69l.26.71 2.6.11-6.28-8.11-2.52.19Z"/><path d="M4.65.7 7.71 0 28 56.35l-6.8-10.28Z" fill="url(#h9-a)"/><path d="m4 .84 9.19 21.28 8.9 24.76-.88 3.28-10-26.36a3 3 0 0 0-1.59-1.69L8 21.34a3.06 3.06 0 0 1-1.62-1.75L0 1.75Z" fill="url(#h9-b)"/><path d="m28 56.35-6.74-6.19-.18-6.25Z" fill="url(#h9-c)"/><path d="M7.69 16.22c-.88-2.58-3.45-10.3-5-15.07L5.44.51l7.77 21.61C12 18.62 9 20 7.69 16.22Z" fill="url(#h9-d)"/></symbol><filter id="h9-e"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h9-e)"><path d="M69.11 124.72h81.78L110 165.6ZM110 156.05l24.58-24.58H85.41Z" fill="url(#h9-f)"/><path d="M85.28 132h49.44l1.07-1H84.21Z" fill="url(#h9-g)"/><path d="m109.58 155.72.42 1L135.79 131l-2.49 1Z" fill="url(#h9-h)"/><path d="m150.49 125.21 1.68-1H67.83l1.64 1Z" fill="url(#h9-i)"/><path d="m86.7 132-2.49-1L110 156.76v-1.46Z" fill="url(#h9-j)"/><path d="M149.68 125.21 110 164.9v1.45l42.17-42.17Z" fill="url(#h9-k)"/><path d="m70.32 125.21-2.49-1L110 166.35v-1.45Z" fill="url(#h9-l)"/><use height="56.35" transform="translate(107.34 104.91)" width="27.97" xlink:href="#h9-m"/><use height="56.35" transform="matrix(-1 0 0 1 112.66 104.91)" width="27.97" xlink:href="#h9-m"/><path d="M110 95.9a6.1 6.1 0 1 0 6.1 6.1 6.1 6.1 0 0 0-6.1-6.1Zm0 9.09a3 3 0 1 1 3-3 3 3 0 0 1-3 3.01Z" fill="url(#h9-n)" stroke="url(#h9-o)"/><circle cx="110" cy="102" fill="none" r="3" stroke="url(#h9-p)" stroke-width="1.25"/></g>'
					)
				)
			);
	}
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import './ICategories.sol';

interface IHardwareSVGs {
    struct HardwareData {
        string title;
        ICategories.HardwareCategories hardwareType;
        string svgString;
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

interface ICategories {
    enum FieldCategories {
        MYTHIC,
        HERALDIC
    }

    enum HardwareCategories {
        STANDARD,
        SPECIAL
    }
}