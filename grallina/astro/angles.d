// angles.d
//
// Copyright Peter Williams 2014 <pwil3058@bigpond.net.au>.
//
// This file is part of grallina.
//
// grallina is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 3
// of the License, or (at your option) any later version, with
// some exceptions, please read the COPYING file.
//
// grallina is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with grallina; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA

module grallina.astro.angles;

import std.math: sin, cos, tan, asin, acos, atan, PI, M_1_PI;

const DEG_PER_RAD = M_1_PI * 180.0;
const RAD_PER_DEG = PI / 180.0;

real sind(real angle) { return sin(angle * RAD_PER_DEG); }
real cosd(real angle) { return cos(angle * RAD_PER_DEG); }
real tand(real angle) { return tan(angle * RAD_PER_DEG); }

real asind(real x) { return asin(x) * DEG_PER_RAD; }
real acosd(real x) { return acos(x) * DEG_PER_RAD; }
real atand(real x) { return atan(x) * DEG_PER_RAD; }
