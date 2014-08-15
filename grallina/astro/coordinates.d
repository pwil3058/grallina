// coordinates.d
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

module grallina.astro.coordinates;

/// Horizon Coordinates
struct HorizonCoords {
    double altitude; /// Altitude in degrees
    double azimuth; /// Azimuth in degrees

    invariant() {
        assert(altitude <= 90.0 && altitude >= -90.0);
        assert(azimuth <= 360.0 && azimuth >= 0.0);
    }
}

/// Equatorial Coordinates
struct EquatorialCoords {
    double declination; /// Declination in degrees
    double right_ascension; ///  Right Ascension in degrees

    invariant() {
        assert(declination <= 90.0 && declination >= -90.0);
        assert(right_ascension <= 360.0 && right_ascension >= 0.0);
    }
}

/// Ecliptic Coordinates
struct EclipticCoords {
    double latitude; /// Declination in degrees
    double longitude; ///  Right Ascension in degrees

    invariant() {
        assert(latitude <= 90.0 && latitude >= -90.0);
        assert(longitude <= 360.0 && longitude >= 0.0);
    }
}
