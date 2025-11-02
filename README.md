# XShope - Product Showcase

A Flutter web application that showcases products with images and data hosted on GitHub and deployed via Netlify.

## Product Management Guide (Owner Only)

### Adding New Products

1. **Upload Product Images:**
   - Go to the `assets/products` folder in your GitHub repository
   - Click "Add file" > "Upload files"
   - Select your product images (recommended size: 800x600px)
   - Commit the changes with a descriptive message

2. **Update Products JSON:**
   - Open the `products.json` file in your GitHub repository
   - Click the edit button (pencil icon)
   - Add a new product entry following this format:
   ```json
   {
     "name": "Product Name",
     "price": 99.99,
     "description": "Detailed product description.",
     "imageUrl": "https://raw.githubusercontent.com/xyoni25/xshope/main/assets/products/your-image-name.jpg",
     "rating": 4.5,
     "category": "Category Name",
     "inStock": true,
     "features": [
       "Feature 1",
       "Feature 2",
       "Feature 3",
       "Feature 4"
     ]
   }
   ```
