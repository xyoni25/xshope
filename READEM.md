# XShope - Product Showcase

A Flutter web application that showcases products with images and data hosted on GitHub and deployed via Netlify.

## Features

- Product listing with images hosted on GitHub
- Category filtering
- Search functionality
- Favorites system with local storage
- Responsive design for mobile and desktop
- Dark and light theme support

## Repository Structure

- `/assets`: Contains all product images and banner
  - `/assets/products`: Individual product images
  - `/assets/banner.jpg`: Banner image for the homepage
- `/products.json`: Product data in JSON format

## How to Update Products

1. Add new product images to the `/assets/products/` directory
2. Update the `products.json` file with new product information
3. Commit and push changes to GitHub
4. The app will automatically display the updated products

## Development

This project is built with Flutter and uses the following packages:
- http: For fetching product data
- cached_network_image: For efficient image loading
- provider: For state management
- shared_preferences: For storing favorites
- url_launcher: For opening links

## Deployment

This project is deployed on Netlify and automatically updates when changes are pushed to the main branch.
