import type { Config } from "tailwindcss"

const config = {
  darkMode: "class",
  content: [
    "./pages/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./app/**/*.{ts,tsx}",
    "./src/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
    "./hooks/**/*.{ts,tsx}",
    "./contexts/**/*.{ts,tsx}",
    "*.{js,ts,jsx,tsx,mdx}",
  ],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
          50: "#fef7ff",
          100: "#fdeeff",
          200: "#fbd5ff",
          300: "#f8b3ff",
          400: "#f282ff",
          500: "#e951ff",
          600: "#d929f5",
          700: "#be1dd8",
          800: "#9c1bb0",
          900: "#801b8f",
          950: "#550a5c",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        sidebar: {
          DEFAULT: "hsl(var(--sidebar))",
          foreground: "hsl(var(--sidebar-foreground))",
          hover: "hsl(var(--sidebar-hover))",
          active: "hsl(var(--sidebar-active))",
        },
        // Design Inspiration inspired colors
        brand: {
          navy: {
            DEFAULT: "#001447",
            light: "#003d7a",
            dark: "#000a24",
          },
          green: {
            DEFAULT: "#88e7ae",
            light: "#a3efbf",
            dark: "#6dd896",
          },
          beige: {
            DEFAULT: "#f3efe6",
            light: "#f8f5ed",
            dark: "#eee9df",
          },
          yellow: {
            DEFAULT: "#ffd93d",
            light: "#ffe066",
            dark: "#e6c234",
          },
        },
        // Chart colors for analytics
        chart: {
          1: "hsl(var(--chart-1))",
          2: "hsl(var(--chart-2))",
          3: "hsl(var(--chart-3))",
          4: "hsl(var(--chart-4))",
          5: "hsl(var(--chart-5))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": {
          from: { height: "0" },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: "0" },
        },
        "fade-in": {
          from: { opacity: "0", transform: "translateY(10px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        "slide-in": {
          from: { transform: "translateX(100%)" },
          to: { transform: "translateX(0)" },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
        "fade-in": "fade-in 0.3s ease-out",
        "slide-in": "slide-in 0.3s ease-out",
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        display: ["Cal Sans", "Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "Menlo", "Monaco", "monospace"],
      },
      backdropBlur: {
        xs: "2px",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
  safelist: [
    // Sign out button classes
    "text-red-500",
    "hover:text-red-700",
    "text-red-600",
    "text-red-400",
    "gap-2",
    "mt-auto",
    "cursor-pointer",

    // Hero section specific classes - critical for static rendering
    "text-5xl",
    "md:text-7xl",
    "text-xl",
    "md:text-2xl",
    "text-4xl",
    "md:text-5xl",
    "font-bold",
    "font-semibold",
    "font-medium",
    "mb-6",
    "mb-8",
    "pt-32",
    "pb-20",
    "px-4",
    "px-8",
    "py-2",
    "py-4",
    "max-w-3xl",
    "max-w-4xl",
    "max-w-7xl",
    "mx-auto",
    "text-center",
    "leading-relaxed",
    "inline-flex",
    "items-center",
    "justify-center",
    "rounded-full",
    "bg-opacity-20",
    "border-opacity-30",
    "border-opacity-50",
    "bg-opacity-50",

    // Landing navbar and hero text colors
    "bg-black",
    "text-white",
    "text-gray-300",
    "text-gray-400",
    "text-green-400",
    "hover:text-white",
    "hover:text-red-400",
    "bg-red-600",
    "hover:bg-red-700",
    "hover:bg-gray-800",
    "border-gray-600",
    "border-gray-700",
    "border-gray-800",
    "border-red-600",

    // Card and layout classes
    "bg-gray-900",
    "bg-gray-800",
    "hover:border-red-600",
    "shadow-md",

    // Ensure commonly used text colors are never purged
    "text-gray-100",
    "text-gray-200",
    "text-gray-500",
    "text-gray-600",
    "text-gray-700",
    "text-blue-500",
    "text-blue-600",
    "text-green-500",
    "text-green-600",
    "text-yellow-500",
    "text-yellow-600",
    "text-purple-500",
    "text-purple-600",
    "text-pink-500",
    "text-pink-600",
    "text-indigo-500",
    "text-indigo-600",

    // Background colors
    "bg-white",
    "bg-gray-50",
    "bg-gray-100",
    "bg-gray-200",

    // Border colors
    "border-white",
    "border-gray-200",
    "border-gray-300",

    // Z-index classes
    "z-50",
    "z-40",
    "z-30",
    "z-10",

    // Backdrop blur
    "backdrop-blur",
    "backdrop-blur-sm",
    "backdrop-blur-md",

    // Transition classes
    "transition",
    "transition-colors",
    "transition-all",
    "duration-300",

    // Spacing classes
    "space-y-4",
    "gap-4",
    "gap-8",
    "ml-2",
    "mr-2",
    "h-5",
    "w-5",
    "h-8",
    "w-8",
    "h-12",
    "w-12",
    "h-16",
    "w-16",
    "h-20",
    "w-20",

    // Grid and flex classes
    "grid",
    "grid-cols-1",
    "md:grid-cols-2",
    "lg:grid-cols-3",
    "flex",
    "flex-col",
    "sm:flex-row",
  ],
} satisfies Config

export default config
