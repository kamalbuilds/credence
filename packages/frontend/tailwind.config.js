/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        mantle: {
          primary: '#00D4AA',
          secondary: '#1a1a2e',
          dark: '#0f0f1a',
          accent: '#4ecdc4',
          warning: '#ffd93d',
          success: '#6bcb77',
          error: '#ff6b6b',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-mantle': 'linear-gradient(135deg, #00D4AA 0%, #4ecdc4 100%)',
      },
    },
  },
  plugins: [],
};
