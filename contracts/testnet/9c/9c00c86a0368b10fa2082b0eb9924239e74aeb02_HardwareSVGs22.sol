// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.9;

import '../../../interfaces/IHardwareSVGs.sol';
import '../../../interfaces/ICategories.sol';

/// @dev Experimenting with a contract that holds huuuge svg strings
contract HardwareSVGs22 is IHardwareSVGs, ICategories {
	function hardware_80() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Necklace',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientTransform="matrix(0, 1, 1, 0, -104.2, 104.2)" gradientUnits="userSpaceOnUse" id="h80-a" x1="-104.2" x2="-88.77" y1="107.01" y2="107.01"><stop offset="0" stop-color="#fff"/><stop offset="0.5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(0, 1, 1, 0, -104.2, 104.2)" gradientUnits="userSpaceOnUse" id="h80-b" x1="-103.34" x2="-89.63" y1="108.51" y2="108.51"><stop offset="0" stop-color="gray"/><stop offset="0.5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient gradientTransform="matrix(0, 1, 1, 0, -108.85, 108.85)" gradientUnits="userSpaceOnUse" id="h80-c" x1="-108.85" x2="-103.34" y1="113.74" y2="113.74"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="translate(8072.29 8217.09) rotate(-90)" id="h80-d" x1="8197.87" x2="8192.37" xlink:href="#h80-c" y1="-8067.4" y2="-8067.4"/><linearGradient id="h80-e" x1="-102.44" x2="-107.35" xlink:href="#h80-c" y1="115.24" y2="115.24"/><linearGradient gradientTransform="translate(8072.29 8217.09) rotate(-90)" id="h80-f" x1="8193.87" x2="8198.77" xlink:href="#h80-c" y1="-8065.9" y2="-8065.9"/><clipPath id="h80-g"><path d="M160,72v75a50,50,0,0,1-100,0V72Z" fill="none"/></clipPath><filter id="h80-h" name="shadow"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-i" x1="110" x2="110" xlink:href="#h80-a" y1="175.44" y2="148.56"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-j" x1="96.56" x2="123.44" xlink:href="#h80-a" y1="162" y2="162"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-k" x1="106.86" x2="111.04" xlink:href="#h80-c" y1="182.56" y2="155.17"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-l" x1="110" x2="110" xlink:href="#h80-b" y1="131" y2="131"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-m" x1="58.34" x2="110.75" xlink:href="#h80-b" y1="102.68" y2="102.68"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-n" x1="86.51" x2="86.51" xlink:href="#h80-c" y1="132.5" y2="71.84"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-o" x1="107.67" x2="112.33" xlink:href="#h80-c" y1="177.3" y2="146.81"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-p" x1="110" x2="110" xlink:href="#h80-c" y1="142.75" y2="128.75"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-q" x1="110" x2="110" xlink:href="#h80-c" y1="130" y2="141.5"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-r" x1="110" x2="161.66" xlink:href="#h80-b" y1="102.68" y2="102.68"/><linearGradient gradientTransform="matrix(1, 0, 0, 1, 0, 0)" id="h80-s" x1="135.24" x2="135.24" xlink:href="#h80-c" y1="132.5" y2="71.84"/><linearGradient gradientTransform="matrix(0, -1, -1, 0, 8490.22, -7930.81)" id="h80-t" x1="-8079.37" x2="-8069.59" xlink:href="#h80-c" y1="8380.72" y2="8380.72"/><linearGradient gradientTransform="matrix(0, -1, -1, 0, 8490.22, -7930.81)" id="h80-u" x1="-8069.59" x2="-8079.37" xlink:href="#h80-c" y1="8379.72" y2="8379.72"/><symbol id="h80-w" viewBox="0 0 7.14 15.42"><path d="M1.5,7.71a7.75,7.75,0,0,0,4.14,6.86l-1.5.85h0A9.25,9.25,0,0,1,4.14,0h0l1.5.85A7.75,7.75,0,0,0,1.5,7.71Z" fill="url(#h80-a)"/><path d="M3,7.71c0,4.26,4.13,6,4.14,6l-1.5.9A7.75,7.75,0,0,1,5.64.85l1.5.91S3,3.41,3,7.71Z" fill="url(#h80-b)"/></symbol><symbol id="h80-v" viewBox="0 0 7.14 24.73"><use height="15.42" transform="translate(0 4.65)" width="7.14" xlink:href="#h80-w"/><polygon fill="url(#h80-c)" points="5.64 5.5 4.14 4.65 4.14 0 5.64 1.5 5.64 5.5"/><polygon fill="url(#h80-d)" points="5.64 19.22 4.14 20.07 4.14 24.73 5.64 23.22 5.64 19.22"/><polygon fill="url(#h80-e)" points="7.14 6.41 5.64 5.5 5.64 1.5 7.14 3 7.14 6.41"/><polygon fill="url(#h80-f)" points="7.14 18.32 5.64 19.22 5.64 23.22 7.14 21.73 7.14 18.32"/></symbol></defs><g clip-path="url(#h80-g)"><g filter="url(#h80-h)"><path d="M110.7,161.3l-.7-12.74h0c-.88,2.72-4.38,2.77-4.38,6.18,0,2.46,3.57,3,1.86,4.74s-2.28-1.86-4.74-1.86c-3.41,0-3.46,3.5-6.18,4.38l12.82.5.62,12.94h0c.88-2.72,4.38-2.77,4.38-6.18,0-2.46-3.57-3-1.86-4.74s2.28,1.86,4.74,1.86c3.41,0,3.46-3.5,6.18-4.38Z" fill="url(#h80-i)"/><path d="M123.44,162c-2.72-.88-2.77-4.38-6.18-4.38-2.46,0-3,3.57-4.74,1.86s1.86-2.28,1.86-4.74c0-3.41-3.5-3.46-4.38-6.18V162H96.56c2.72.88,2.77,4.38,6.18,4.38,2.46,0,3-3.57,4.74-1.86s-1.86,2.28-1.86,4.74c0,3.41,3.5,3.46,4.38,6.18V162Z" fill="url(#h80-j)"/><path d="M113.24,162.48a2.67,2.67,0,0,0-2.76,2.76c0,1.62,2.12,2.21,2.12,4s-1.7,2.17-2.6,3.27c-.9-1.1-2.6-1.5-2.6-3.27s2.12-2.36,2.12-4a2.67,2.67,0,0,0-2.76-2.76c-1.62,0-2.21,2.12-4,2.12s-2.17-1.7-3.27-2.6c1.1-.9,1.5-2.6,3.27-2.6s2.36,2.12,4,2.12a2.67,2.67,0,0,0,2.76-2.76c0-1.62-2.12-2.21-2.12-4s1.7-2.17,2.6-3.27c.9,1.1,2.6,1.5,2.6,3.27s-2.12,2.36-2.12,4a2.67,2.67,0,0,0,2.76,2.76c1.62,0,2.21-2.12,4-2.12s2.17,1.7,3.27,2.6c-1.1.9-1.5,2.6-3.27,2.6S114.86,162.48,113.24,162.48Z" fill="url(#h80-k)"/><path d="M110,131" fill="none" stroke="url(#h80-l)" stroke-miterlimit="10"/><path d="M110.2,132.76H110c-13,0-25.48-10.26-37.23-30.5A179.86,179.86,0,0,1,59.05,72.07" fill="none" stroke="url(#h80-m)" stroke-miterlimit="10" stroke-width="1.5"/><path d="M60,72s19.69,60,50,60a22.76,22.76,0,0,0,3.42-.26" fill="none" stroke="url(#h80-n)" stroke-miterlimit="10"/><path d="M104.9,132.94a15,15,0,0,0,3.46.52l.36-1,2.55-1.93Z"/><use height="24.72" transform="translate(93.5 149.69)" width="7.14" xlink:href="#h80-v"/><use height="24.72" transform="translate(122.36 145.55) rotate(90)" width="7.14" xlink:href="#h80-v"/><use height="24.72" transform="translate(126.5 174.42) rotate(180)" width="7.14" xlink:href="#h80-v"/><use height="24.72" transform="translate(97.64 178.55) rotate(-90)" width="7.14" xlink:href="#h80-v"/><path d="M125,162.05a7.77,7.77,0,0,0-4.14-6.86v-4h-4a7.75,7.75,0,0,0-13.72,0h-4v4a7.75,7.75,0,0,0,0,13.72v4h4a7.76,7.76,0,0,0,13.72,0h4v-4A7.75,7.75,0,0,0,125,162.05Z" fill="none" stroke="url(#h80-o)" stroke-miterlimit="10"/><circle cx="110" cy="135.75" fill="none" r="6" stroke="url(#h80-p)" stroke-miterlimit="10" stroke-width="2"/><circle cx="110" cy="135.75" fill="none" r="5" stroke="url(#h80-q)" stroke-miterlimit="10" stroke-width="1.5"/><path d="M161,72.07c0,.17-19.78,60.69-50.95,60.69" fill="none" stroke="url(#h80-r)" stroke-miterlimit="10" stroke-width="1.5"/><path d="M110,132c30.31,0,50-60,50-60" fill="none" stroke="url(#h80-s)" stroke-miterlimit="10"/><path d="M110,148.56l-1-.95v-7.83l1-1Z" fill="url(#h80-t)"/><path d="M110,138.78l1,1v7.83l-1,.95Z" fill="url(#h80-u)"/></g></g>'
					)
				)
			);
	}

	function hardware_81() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Pillar and Twin Quatrefoils',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h81-a" x1="13.44" x2="13.44" y1="26.89" y2="0"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="#848484"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h81-d" x1="0" x2="26.89" xlink:href="#h81-a" y1="13.44" y2="13.44"/><linearGradient gradientUnits="userSpaceOnUse" id="h81-e" x1="10.31" x2="14.49" y1="34" y2="6.61"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16387.69)" gradientUnits="userSpaceOnUse" id="h81-b" x2="17.69" y1="16386.68" y2="16386.68"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientTransform="matrix(1 0 0 -1 0 16387.69)" gradientUnits="userSpaceOnUse" id="h81-c" x2="17.69" y1="16385.56" y2="16385.56"><stop offset="0" stop-color="gray"/><stop offset=".5" stop-color="#fff"/><stop offset="1" stop-color="gray"/></linearGradient><linearGradient id="h81-g" x1="96.73" x2="123.27" xlink:href="#h81-b" y1="89.24" y2="89.24"/><linearGradient gradientUnits="userSpaceOnUse" id="h81-h" x1="96.99" x2="120" y1="132.46" y2="132.46"><stop offset="0" stop-color="gray"/><stop offset=".24" stop-color="#4b4b4b"/><stop offset=".68" stop-color="#fff"/><stop offset="1" stop-color="#4b4b4b"/></linearGradient><linearGradient id="h81-i" x1="98.29" x2="121.71" xlink:href="#h81-b" y1="175.4" y2="175.4"/><symbol id="h81-j" viewBox="0 0 17.69 3.69"><path d="M0 1.34 1.34 0h15l1.35 1.34-8.85.68Z" fill="url(#h81-b)"/><path d="M17.69 1.34 16.13 2.9H1.56L0 1.34Z" fill="url(#h81-c)"/><path d="M16.34 2.69h-15v1h15Z"/></symbol><symbol id="h81-k" viewBox="0 0 26.89 26.89"><path d="M20.7 9.06c-2.46 0-3.02 3.58-4.74 1.86s1.87-2.27 1.87-4.74c0-3.4-3.5-3.46-4.39-6.18l-.53 12.85-12.91.6c2.72.87 2.77 4.38 6.18 4.38 2.47 0 3.03-3.58 4.74-1.87s-1.86 2.28-1.86 4.74c0 3.41 3.5 3.47 4.38 6.19l.54-12.86 12.9-.59c-2.71-.88-2.77-4.38-6.18-4.38Z" fill="url(#h81-a)"/><path d="M13.44 13.44H0c2.72-.88 2.77-4.38 6.18-4.38 2.47 0 3.03 3.58 4.74 1.86S9.06 8.65 9.06 6.18c0-3.4 3.5-3.46 4.38-6.18v26.89c.88-2.72 4.39-2.78 4.39-6.19 0-2.46-3.58-3.02-1.87-4.74s2.28 1.87 4.74 1.87c3.41 0 3.47-3.5 6.19-4.39Z" fill="url(#h81-d)"/><path d="M16.68 13.93a2.66 2.66 0 0 0-2.75 2.75c0 1.63 2.11 2.22 2.11 3.99s-1.7 2.16-2.6 3.26c-.9-1.1-2.6-1.5-2.6-3.26s2.12-2.36 2.12-3.99a2.47 2.47 0 0 0-.78-1.97 2.47 2.47 0 0 0-1.97-.78c-1.63 0-2.22 2.11-3.99 2.11s-2.17-1.7-3.26-2.6c1.1-.9 1.5-2.6 3.26-2.6s2.36 2.12 3.99 2.12a2.47 2.47 0 0 0 1.97-.78 2.47 2.47 0 0 0 .78-1.97c0-1.63-2.11-2.22-2.11-3.99s1.7-2.16 2.6-3.26c.9 1.1 2.6 1.5 2.6 3.26s-2.12 2.36-2.12 3.99a2.47 2.47 0 0 0 .78 1.97 2.47 2.47 0 0 0 1.97.78c1.63 0 2.21-2.11 3.99-2.11s2.16 1.7 3.26 2.6c-1.1.9-1.5 2.6-3.26 2.6s-2.36-2.12-3.99-2.12Z" fill="url(#h81-e)"/></symbol><filter id="h81-f"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h81-f)"><path d="M96.73 87h26.54v2.99L110 91.49l-13.27-1.5Z" fill="url(#h81-g)"/><path d="m117.12 163.52-1.82-68.88c2.7-2.9 5.35-3.42 7.94-4.65H96.76c2.59 1.23 5.24 1.75 7.94 4.65l-1.82 68.88a4.39 4.39 0 0 1-2.78 4.05l-.06.02v7.35h19.92v-7.35l-.06-.02a4.39 4.39 0 0 1-2.78-4.05Z" fill="url(#h81-h)"/><path d="M98.3 173.8h23.4v3.2H98.3Z" fill="url(#h81-i)"/><use height="3.69" transform="matrix(.7464 0 0 1 103.4 102)" width="17.69" xlink:href="#h81-j"/><use height="3.69" transform="matrix(.9469 0 0 1 101.63 159.31)" width="17.69" xlink:href="#h81-j"/><use height="3.69" transform="matrix(.9469 0 0 1 101.63 155.62)" width="17.69" xlink:href="#h81-j"/><use height="3.69" transform="matrix(1.327 0 0 1 98.26 167.59)" width="17.69" xlink:href="#h81-j"/><path d="M115.33 95.64h-10.68l-.22-1.26h11.12l-.22 1.26z"/><use height="26.89" transform="translate(121.56 118.56)" width="26.89" xlink:href="#h81-k"/><use height="26.89" transform="translate(71.56 118.56)" width="26.89" xlink:href="#h81-k"/></g>'
					)
				)
			);
	}

	function hardware_82() public pure returns (HardwareData memory) {
		return
			HardwareData(
				'Horse-head Gables',
				HardwareCategories.STANDARD,
				string(
					abi.encodePacked(
						'<defs><linearGradient gradientUnits="userSpaceOnUse" id="h82-a" x1="-1.12" x2="52.89" y1="73.3" y2="13.97"><stop offset="0" stop-color="#4b4b4b"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient gradientUnits="userSpaceOnUse" id="h82-b" x1="22.37" x2="22.37" y1="14.89" y2="65.46"><stop offset="0" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h82-c" x1="65.95" x2="65.95" xlink:href="#h82-a" y1="9.24" y2="26.66"/><linearGradient id="h82-d" x1="51.46" x2="51.46" xlink:href="#h82-a" y1="8.81" y2="30.66"/><linearGradient gradientUnits="userSpaceOnUse" id="h82-e" x2="20" y1="63.96" y2="63.96"><stop offset="0" stop-color="#fff"/><stop offset=".5" stop-color="gray"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="h82-f" x1="36.65" x2="36.65" xlink:href="#h82-b" y1="1.77" y2="63.46"/><linearGradient id="h82-g" x1="40.65" x2="40.65" xlink:href="#h82-a" y1="15.59" y2="11.76"/><linearGradient id="h82-j" x1="110" x2="110" xlink:href="#h82-b" y1="128.29" y2="135.29"/><symbol id="h82-i" viewBox="0 0 73.13 65.46"><path d="M73.13 11.86c-1.5-.59-3.62-3.05-5-5C62.26-1.43 54.5-1.42 48.76 2.7c-4.28 3.07-8.6 8.53-12.2 9.05l6.84 3.43L0 65.46s13.89-2 20 0l29-34.8c-1.92-10.59 1.59-20.64 7.74-18.9 0 3.83.23 7.67-1.12 11.21l3.33 3.69s2.4-7.65 6.1-12.98c1.73-2.5 8.08-1.82 8.08-1.82Z" fill="url(#h82-a)"/><path d="M44.74 14.89h-2.6L0 65.46l5.03-1.5 39.71-49.07z" fill="url(#h82-b)"/><path d="m73.13 11.86-9.06-2.62-5.3 14.16.18 3.26a129.57 129.57 0 0 1 7.4-12.55c1.73-2.5 4.4-.41 6.78-2.25Z" fill="url(#h82-c)"/><path d="M56.74 11.76a19.16 19.16 0 0 1 2.78-2c-14.85-6.04-16.1 18.87-16.1 18.87L49 30.66c.94-10.04 1.42-18.9 7.74-18.9Z" fill="url(#h82-d)"/><path d="m18.59 62.46-12.45.13L0 65.46h20l-1.41-3z" fill="url(#h82-e)"/><path d="M4.27 63.46 44.74 14.9a15.33 15.33 0 0 1-4.33-2.59c3.83-2.4 7.32-6.31 9.56-8 10.38-7.78 17.52 4.67 19.05 6.37 0 0-2.82.21-3.68 1.55s-4.9 8.1-6.57 11.18l-1.37-1.16c1.66-4.29.62-9.08 2.12-12.48-4.07-.52-8.92-.3-10.83 7.48-.83 3.37-1.68 12.7-1.68 12.7l-27.95 33.5Z" fill="url(#h82-f)"/><path d="m36.57 11.76 3.84.54 4.33 2.6-3.18.7Z" fill="url(#h82-g)"/></symbol><filter id="h82-h"><feDropShadow dx="0" dy="2" stdDeviation="0"/></filter></defs><g filter="url(#h82-h)"><use height="65.46" transform="matrix(-1 0 0 1 145 96.33)" width="73.13" xlink:href="#h82-i"/><path d="m121.4 133.48-1.71.97-7.27 9.15-.34 2.69-4.09-4.71 11.05-11.18 2.36 3.08z"/><use height="65.46" transform="translate(75 96.33)" width="73.13" xlink:href="#h82-i"/><circle cx="110" cy="131.79" r="3" stroke="url(#h82-j)"/></g>'
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