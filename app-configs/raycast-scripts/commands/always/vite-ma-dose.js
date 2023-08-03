#!/usr/bin/env node

// @raycast.title Check Vaccination Slot
//
// @raycast.mode compact
// @raycast.icon 🗓
// @raycast.schemaVersion 1

const fetch = require("node-fetch");
const puppeteer = require("puppeteer");
require("dotenv").config({ path: "../../.env" });

// https://www.movable-type.co.uk/scripts/latlong.html
function distance({ lat1, lon1, lat2, lon2 }) {
  const R = 6371e3; // metres
  const φ1 = (lat1 * Math.PI) / 180; // φ, λ in radians
  const φ2 = (lat2 * Math.PI) / 180;
  const Δφ = ((lat2 - lat1) * Math.PI) / 180;
  const Δλ = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
    Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  const d = R * c; // in metres
  return d;
}

function chunk(arr, limit = 10) {
  const count = Math.ceil(arr.length / limit);
  const chunks = [];
  for (let i = 0; i < count; i++) {
    chunks.push(arr.slice(i * limit, (i + 1) * limit));
  }
  return chunks;
}

(async function () {
  //   const browser = await puppeteer.launch();
  //   const page = await browser.newPage();
  //   await page.goto(
  //     "https://vitemadose.covidtracker.fr/centres-vaccination-covid-dpt95-val_d_oise/commune95203-95600-eaubonne/recherche-dose_rappel/en-triant-par-distance"
  //   );
  //   await page.waitForNetworkIdle();
  //   await page.waitForFunction(() => {
  //     try {
  //       return document
  //         .querySelector("vmd-app")
  //         .shadowRoot.querySelector("vmd-rdv-par-commune")
  //         .shadowRoot.querySelector(".search-standard")
  //         .innerText.includes("créneaux de vaccination trouvés autour de");
  //     } catch (e) {
  //       return false;
  //     }
  //   });
  //   const results = await page.evaluate(() => {
  //     const cards = document
  //       .querySelector("vmd-app")
  //       .shadowRoot.querySelector("vmd-rdv-par-commune")
  //       .shadowRoot.querySelectorAll("vmd-appointment-card");
  //     return Array.from(cards)
  //       .map((card) => {
  //         const isPfizer = card.shadowRoot
  //           .querySelector("vmd-appointment-metadata[icon=vmdicon-syringe]")
  //           .querySelector(".text-description")
  //           .innerText.includes("Pfizer-BioNTech");
  //         if (!isPfizer) {
  //           return null;
  //         }
  //         const slot = card.shadowRoot
  //           .querySelector(".card-title.h5")
  //           .innerText.split(" ")[0];
  //         if (Number(slot) < 2) {
  //           return null;
  //         }
  //         const distance = card.shadowRoot
  //           .querySelector(".distance")
  //           .innerText.trim()
  //           .slice(2);
  //         const address = card.shadowRoot
  //           .querySelector("vmd-appointment-metadata[icon=vmdicon-geo-alt-fill]")
  //           .querySelector(".text-description").innerText;
  //         return { slot, distance, address };
  //       })
  //       .filter(Boolean);
  //   });
  //   console.log("# results", results);
  //   await browser.close();

  //

  const { centres_disponibles } = await (
    await fetch("https://vitemadose.gitlab.io/vitemadose/95.json")
  ).json();

  const results = centres_disponibles
    .filter((center) => center.vaccine_type.includes("Pfizer-BioNTech"))
    .filter(
      (center) =>
        distance({
          lat1: process.env.MY_LATITUDE,
          lon1: process.env.MY_LONGITUDE,
          lat2: center.location.latitude,
          lon2: center.location.longitude,
        }) <= 5000
    )
    .map((center) => ({
      internal_id: center.internal_id,
      url: center.url,
      title: center.nom,
      address: center.metadata.address,
      distance: distance({
        lat1: process.env.MY_LATITUDE,
        lon1: process.env.MY_LONGITUDE,
        lat2: center.location.latitude,
        lon2: center.location.longitude,
      }),
    }))
    .sort((a, b) => a.distance - b.distance);

  console.log(`# got ${results.length} result(s)`);
  const chunkedResults = chunk(results);

  for (let batch of chunkedResults) {
    await fetch(process.env.DISCORD_VITEMADOSE, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        username: "vite ma dose",
        embeds: batch.map((r) => ({
          title: r.title,
          url: r.url,
          description: r.address,
          fields: [
            {
              name: "distance",
              value: Math.round(10 * (r.distance / 1000)) / 10 + "km",
            },
            {
              name: "id",
              value: r.internal_id,
              inline: true,
            },
          ],
        })),
      }),
    });
  }
})();
