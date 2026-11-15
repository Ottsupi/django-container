/**
 * Theme handler for Tailwind that adds "dark" to <html>.
 * Switches between system theme and the opposite theme.
 *
 * ## Usage
 *
 * Invoke the toggleTheme() method
 * ```
 * <button x-data @click="$store.theme.toggleTheme()">
 *   Click me
 * </button>
 * ```
 *
 * Check current theme to display appropriate icon
 * ```
 * <template x-if="$store.theme.current === 'dark'">
 *   ...
 * </template>
 * ```
 */
document.addEventListener("alpine:init", () => {
    console.log("Initializing Alpine theme store");
    Alpine.store("theme", {
        current: localStorage.getItem("theme") || "system",
        isSystemDark: window.matchMedia("(prefers-color-scheme: dark)").matches,

        init() {
            const mediaQuery = window.matchMedia(
                "(prefers-color-scheme: dark)",
            );
            mediaQuery.addEventListener("change", (e) => {
                this.isSystemDark = e.matches;
                if (this.current === "system") this.apply();
            });
            this.apply();
        },

        apply() {
            const isDark =
                this.current === "dark" ||
                (this.current === "system" && this.isSystemDark);
            document.documentElement.classList.toggle("dark", isDark);
        },

        set(newTheme) {
            this.current = newTheme;
            localStorage.setItem("theme", newTheme);
            this.apply();
        },

        toggleTheme() {
            if (this.current === "light") {
                this.isSystemDark
                    ? this.set("system")
                    : this.set("dark");
            } else if (this.current === "dark") {
                this.isSystemDark
                    ? this.set("light")
                    : this.set("system");
            } else {
                const isCurrentlyDark =
                    document.documentElement.classList.contains("dark");
                if (!isCurrentlyDark) {
                    this.isSystemDark
                        ? this.set("system")
                        : this.set("dark");
                } else {
                    this.isSystemDark
                        ? this.set("light")
                        : this.set("system");
                }
            }
        },
    });
});
