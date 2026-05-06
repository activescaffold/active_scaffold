Jekyll::Hooks.register :site, :post_write do |site|
  system("npx --yes pagefind --site _site --glob 'doc/*/index.html'")
end
