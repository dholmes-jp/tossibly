// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import "bootstrap"

// Page curtain transition (see components/_transitions.scss)
const curtain = document.getElementById("page-curtain")
const EASE = "cubic-bezier(.76, 0, .24, 1)"
const slide = (from, to) =>
  curtain.animate(
    [{ transform: `translateY(${from})` }, { transform: `translateY(${to})` }],
    { duration: 500, easing: EASE, fill: "forwards" }
  ).finished

document.addEventListener("turbo:before-render", async (event) => {
  if (!curtain || matchMedia("(prefers-reduced-motion: reduce)").matches) return
  event.preventDefault()
  await slide("100%", "0")        // rise and cover the old page
  event.detail.resume()           // Turbo swaps in the new page underneath
  await slide("0", "-100%")       // keep rising, off the top, revealing it
  curtain.getAnimations().forEach((a) => a.cancel())  // park it below again
})
