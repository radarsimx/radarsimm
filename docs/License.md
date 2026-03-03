# RadarSim.License

[&larr; Back to index](index.md)

License - Class for handling RadarSimM license management This class provides static methods for managing RadarSimM licenses, including activating license files and retrieving license information.

## Methods

### `set_license(lic_path)`

Activate license file(s) If a license file path is provided, activates that specific file. If no path is provided, searches the package directory for all license files matching 'license_RadarSimM_*.lic' pattern.

**Parameters:**

- lic_path (string): Path to a specific license file.
- If not specified, searches the package directory.

**Example:**

```matlab
RadarSim.License.set_license();
RadarSim.License.set_license('/path/to/license_RadarSimM_M1772546579.lic');
```

### `license_info = get_info()`

Get license information

**Returns:** license_info (string): License information string.

**Example:**

```matlab
info = RadarSim.License.get_info();
```

### `set(license_path, product_name)`

Set a specific license file Activates a single license file by its full path.

**Parameters:**

- license_path (string): Full path to the license file.
- product_name (string): Product name (default: 'RadarSimM').

**Example:**

```matlab
RadarSim.License.set('/path/to/license.lic');
```

---
*Copyright (C) 2023 - PRESENT radarsimx.com*
