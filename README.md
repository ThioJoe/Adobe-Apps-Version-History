<div align="center">

# Adobe Apps Version History

**This repository serves as an unofficial archive of the version history of all Adobe Creative Cloud applications.**

<div align="center">
  <h1><a href="https://thiojoe.github.io/Adobe-Apps-Version-History/">🔗 Open the Interactive Release Viewer</a></h1>
  <sub>https://thiojoe.github.io/Adobe-Apps-Version-History/</sub>
</div>

</div>

---

## Why?

Adobe apparently does not provide a public historical log of all app versions and release dates in one place.

So this project periodically fetches, parses, and stores that data for easy reference.

## Exploring the Data

You can browse the data interactively using the **[Live Release Browser](https://thiojoe.github.io/Adobe-Apps-Version-History/)**, which is a purely static HTML frontend hosted on GitHub Pages that reads the JSON data in this repository.

If you want to use the raw data yourself, you can grab the master JSON file here:

* `all_data.json` - Contains the full historical record of all tracked applications and their builds.

## How It Works

* **Automated Fetching:** Updated data is fetched daily at midnight.
* **Data Source:** Data is sourced straight from Adobe's own update servers via an undocumented API endpoint.
  * Note: I've chosen not to publish the exact endpoint here. I figure if Adobe wanted it public they would have made it so.
* **Storage:** The historical build data is appended and saved as JSON. It is stored both as individual files per app (in the `data/` directory) and as a single master dataset (`all_data.json`) in the root directory.

-----

#### Notes
* I don't think Adobe will have a problem with this project, but if for some reason Adobe has any issue with this, they can let me know and I will take it down, or modify it in any way requested.
