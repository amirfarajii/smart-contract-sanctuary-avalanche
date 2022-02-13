//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./PetAccessControl.sol";

contract PityBird is PetAccessControl {
    string constant public name = "Bird";

    function getPart(uint256 _partNumber) public view onlyOwner returns (string memory) {
        string[7] memory parts = [
            //head
            '<g id="head"><g id="head_bird"><path d="M815.436,111.803c-21.754,-0.109 -151.254,2.364 -217.702,88.494c-45.433,58.89 -70.92,147.585 -65.585,235.221c5.619,92.306 167.263,137.701 262.73,139.974c70.925,1.689 262.862,-34.531 264.063,-127.802c1.271,-98.706 -0.581,-181.666 -51.259,-247.393c-55.346,-71.779 -164.872,-88.357 -192.247,-88.494Z" id="BirdColor"/><path d="M1027.77,260.237c-0,0 90.03,116.173 63.109,115.91c-26.921,-0.264 -51.767,-26.557 -51.767,-26.557c-0,0 57.438,71.233 41.561,73.249c-15.876,2.015 -24.831,5.605 -48.201,-19.648" id="BirdColor"/><path d="M954.347,510.228c-0,-0 25.312,45.956 49.393,35.209c24.081,-10.747 2.562,-68.372 2.562,-68.372" id="BirdColor"/><path d="M551.824,329.672c0,0 -32.212,4.499 -42.217,-9.797c-10.005,-14.297 57.819,-48.17 57.819,-48.17c0,0 -38.891,8.652 -48.789,-13.425c-9.897,-22.077 57.529,-37.331 82.189,-42.382" id="BirdColor"/><g id="lips_bird"><path d="M588.997,416.903c-0,-0 133.855,-52.924 181.798,-54.331c47.944,-1.408 206.058,22.983 236.703,54.331c19.634,20.084 -163.9,62.473 -202.965,80.768c-39.065,18.295 -215.536,-80.768 -215.536,-80.768Z" style="fill:#7a3636;stroke:#000;stroke-width:18.2px;"/></g></g></g>',
            //body
            '<g id="belly"><g id="belly_bird"><path serif:id="belly dog" d="M415.695,1012.12c-11.772,16.948 -13.987,46.612 0,60.95c13.415,13.75 42.104,-8.376 44.945,-5.847c-2.674,18.411 -5.794,56.05 17.178,57.177c17.588,0.862 31.899,-12.136 40.512,-22.634c-4.667,25.261 -5.996,45.106 4.145,49.104c13.382,5.275 34.588,-13.584 43.304,-30.194c1.746,21.382 10.321,35.172 20.249,37.569c10.073,2.432 19.971,-4.781 32.203,-22.155c7.702,31.316 15.485,48.911 32.995,50.734c17.818,1.855 32.281,-24.274 40.194,-40.521c4.655,17.069 8.682,34.158 28.367,35.7c16.453,1.29 31.47,-28.365 32.894,-28.341c8.312,24.398 13.471,43.463 34.662,41.544c16.442,-1.489 28.427,-21.136 28.316,-38.894c6.432,23.472 25.069,35.981 42.257,30.512c12.933,-4.115 21.255,-29.183 14.698,-44.54c11.065,16.379 27.347,33.671 59.915,25.529c26.2,-6.55 48.708,-46.293 43.72,-62.855c180.581,-95.528 52.701,-416.681 47.699,-505.625c-4.345,-77.258 -60.877,-137.097 -166.032,-145.88c-44.703,-3.734 -158.866,-0.956 -238.779,42.094c-44.503,23.975 -69.027,59.168 -95.024,103.786c-14.216,24.399 -10.541,78.891 -34.312,110.089c-49.108,64.453 -119.031,204.393 -74.106,302.698Z" id="BirdColor"/><path d="M565.994,684.275c-0,0 -29.178,54.73 -0,63.517c12.555,3.781 23.898,-18.148 29.191,-36.295" id="BirdColor"/><path d="M892.929,845.005c-0,0 0.756,26.465 12.854,28.734c12.099,2.268 20.417,-35.539 21.173,-52.175" id="BirdColor"/><path d="M963.44,872.605c0,-0 24.197,77.127 36.295,73.347c12.099,-3.781 11.343,-35.54 0,-86.202" id="BirdColor"/><path d="M496.894,785.836c-0,0 -44.613,48.394 -18.904,62.005c11.898,6.299 31.002,-9.83 40.076,-21.929" id="BirdColor"/><path d="M801.639,895.67c-0,0 -26.328,54.505 -6.015,60.666c20.312,6.161 30.558,-28.732 30.558,-28.732" id="BirdColor"/><path d="M560.115,820.619c0,0 -11.333,39.412 6.297,40.422c17.63,1.011 19.519,-23.242 19.519,-23.242" id="BirdColor"/></g></g>',
            //right hand
            '<g id="paw_r"><g id="paw_r_bird"><path d="M539.604,527.379c115.809,15.043 74.915,171.144 -13.829,175.396c-55.299,2.65 -124.465,2.57 -200.946,-51.289c-20.766,28.31 -119.795,94.641 -154.358,51.289c28.424,-55.146 92.273,-106.286 161.048,-175.396c49.682,-4.561 159.177,-6.354 208.085,-0Z" id="BirdColor"/><path d="M305.598,607.226c-23.37,49.596 -84.727,144.4 -74.267,148.237c38.235,14.022 87.01,5.981 145.827,-113.581" id="BirdColor"/><path d="M369.928,617.215c-8.715,42.426 -52.751,147.558 -32.953,147.108c35.242,-0.801 67.686,-35.186 102.416,-114.886" id="BirdColor"/></g></g>',
            //left hand
            '<g id="paw_l"><g id="paw_l_bird"><path d="M1008.27,588.601c-55.934,17.76 -107.683,139.042 -11.076,179.326c61.047,25.457 120.756,3.619 219.498,-15.507c20.824,28.268 119.971,85.79 154.445,42.367c-34.464,-45.413 -125.773,-121.71 -194.689,-190.679c-49.691,-4.458 -121.171,-30.433 -168.178,-15.507Z" id="BirdColor"/><path d="M1216.49,703.424c28.144,48.552 102.423,140.455 89.542,144.874c-47.084,16.155 -103.461,12.987 -165.279,-89.177" id="BirdColor"/><path d="M1153.96,722.575c8.854,47.753 50.719,156.223 29.642,156.577c-44.432,0.746 -89.033,-48.642 -117.258,-142.388" id="BirdColor"/></g></g>',
            //left leg
            '<g id="leg_l"><g id="leg_l_bird"><path d="M991.447,1081.42c16.606,21.397 25.263,63.282 35.578,72.473c10.693,9.527 65.308,-5.862 97.347,62.65c32.039,68.512 -58.002,-12.679 -64.643,-10.511c-6.641,2.168 29.663,71.855 16.899,81.594c-12.764,9.739 -44.616,-40.484 -54.165,-49.442c-12.062,-11.315 -7.311,73.393 -26.848,57.133c-19.538,-16.26 -29.477,-72.055 -20.359,-97.495c9.118,-25.44 -74.301,-48.574 -74.348,-60.656c-0.12,-30.713 73.934,-77.142 90.539,-55.746Z" style="fill:#f5aeae;stroke:#05000e;stroke-width:24px;"/><path d="M1130.02,1242.46c0,0 9.786,4.142 13.936,20.542" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1070.55,1285.65c0,0 8.841,4.996 9.806,21.749" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1007.34,1212.87c0,0 4.85,-10.272 28.171,-17.367" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M996.326,1290.89c0,-0 5.924,6.718 -0.915,23.15" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1037.24,1083.45c1.103,-31.996 -10.744,-61.941 -28.661,-72.213c-37.857,-21.705 -164.083,-22.052 -165.273,116.004c-0.277,32.13 36.877,60.996 74.113,65.153c20.297,8.804 19.511,29.321 30.454,24.893c21.242,-8.597 16.709,-34.041 15.959,-48.493c10.936,5.698 33.857,14.751 39.131,10.625c15.098,-11.809 -0.044,-28.389 -2.886,-44.285c3.796,-4.666 42.698,17.036 52.758,2.218c7.339,-10.809 -15.223,-28.162 -11.166,-45.265l-4.429,-8.637Z" id="BirdColor"/></g></g>',
            //right leg
            '<g id="leg_r"><g id="leg_r_bird"><path d="M353.709,969.364c-22.685,9.924 -48.318,40.69 -60.568,43.441c-12.697,2.851 -48.772,-35.927 -104.774,5.898c-56.003,41.824 51.352,17.013 55.605,21.975c4.254,4.963 -55.634,45.738 -49.962,59.916c5.671,14.178 53.308,-12.505 64.849,-15.425c14.578,-3.69 -27.221,64.594 -4.537,60.341c22.685,-4.254 55.577,-45.993 59.831,-71.514c4.253,-25.52 80.31,-5.131 85.776,-15.17c13.894,-25.52 -23.535,-99.387 -46.22,-89.462Z" style="fill:#f5aeae;stroke:#05000e;stroke-width:24px;"/><path d="M170.616,1040.68c0,0 -10.889,-0.028 -26.768,16.305" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M198.491,1103.9c0,-0 -10.801,1.374 -24.445,19.615" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M289.296,1065.25c0,-0 0.798,-10.859 -14.37,-27.854" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M252.883,1145.03c0,0 -9.83,4.683 -17.084,26.277" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M322.984,944.725c13.124,-27.379 54.078,-54.42 72.794,-54.752c39.546,-0.702 139.888,57.439 80.425,173.922c-13.839,27.11 -67.498,35.54 -98.873,21.794c-19.962,-2.003 -28.315,15.59 -35.064,6.805c-13.1,-17.052 1.632,-36.32 8.551,-48.109c-11.173,-0.278 -33.328,-3.286 -35.709,-9.192c-6.816,-16.906 12.457,-23.819 21.668,-35.853c-0.972,-5.675 -41.345,-5.459 -42.846,-22.559c-1.096,-12.475 24.405,-16.602 28.668,-32.843l0.386,0.787Z" id="BirdColor"/></g></g>',
            //add
            '<g id="add"><g id="add_bird"><path d="M1052.28,1052.19c0.74,-33.933 47.497,-37.49 127.326,-40.768c79.829,-3.278 104.302,1.886 120.824,26.055c16.523,24.168 -28.615,65.842 -57.549,72.034c-18.515,-18.718 -31.748,-29.949 -31.748,-29.949l-15.225,32.448c0,-0 -144.563,-16.977 -143.628,-59.82Z" id="BirdColor"/><path d="M955.204,1054.24c42.924,2.35 200.116,1.807 288.608,-6.35" style="fill:none;stroke:#05000e;stroke-width:24px;"/><path d="M1044.74,1002.67c10.866,32.575 64.978,24.303 156.539,7.481c91.561,-16.822 117.807,-27.935 129.416,-55.406c11.609,-27.471 18.945,-109.508 -144.981,-44.966c-15.48,22.707 -27.179,36.864 -27.179,36.864l-26.865,-27.516c-0,-0 -100.65,42.412 -86.93,83.543Z" id="BirdColor"/><path d="M945.202,1020.27c48.858,-9.237 227.259,-48.688 326.14,-80.742" style="fill:none;stroke:#05000e;stroke-width:24px;"/></g></g>'
        ];
        
        return parts[_partNumber];
    }

    function getColor(uint256 _colorId) public view onlyOwner returns (string memory, string memory) {
        string[10] memory colors = [
            'dc2e2e',
            'cc3c00',
            'c30000',
            'e73700',
            'c65a41',
            'c71e3e',
            'ab2124',
            '952e1a',
            '7a1615',
            'fc3e3e'
        ];

        return (colors[_colorId], "BirdColor");
    }
}