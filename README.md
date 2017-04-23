# ImagePreviewer
Small microservice implemented in Elixir that receives an URL and replies back with a preview properties such as image, title and page description.

### Install dependencies
```
mix deps.get
```

### Run the code
```
iex -S mix
```
Then use port 4000

### Run the code
**POST** /image-preview with params containing *url* key

E.g.: POST /image-preview with og:
```
# { url: https://www.lazada.sg/ }
# { url: https://elixirschool.com/ }
# { url: https://github.com/devinus/poison/ }
```

E.g.:
POST /image-preview without og:
```
{ url: http://elixir-lang.org/ }
```