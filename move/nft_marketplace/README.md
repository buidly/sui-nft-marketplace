# Transaction examples

## Place listing with generic NFT

```
# With normal transaction
sui client call \
    --package 0x30a8e86de188c74a56495d19d0667a488289bb2a9a7c4ead7b046728ede3553e \
    --module nft_marketplace \
    --function place_listing \
    --type-args "0x71fc364ce76f54783e10ec08543da1d896e94462e053430aa60860cf9c827017::nft_marketplace::TestnetNFT" \
    --args "0x716587890bee5cb17114ab524b9c85ac83f44f50a888b6d7df86ba260f6c3da4" \
    "0xdf47791502031e34a45cf6e64e74785f65eb8689acdec86d14d69e0f7cd3eb61" \
    100000000 \
    --gas-budget 20000000
```

```
# With Programmable Transaction Block
sui client ptb \
    --assign marketplace @0x716587890bee5cb17114ab524b9c85ac83f44f50a888b6d7df86ba260f6c3da4 \
    --assign nft @0x25bb2091de42935f4f1176e70ef815ac858e2fe37c40819f16bed81cb889cfc7 \
    --assign price 200000000 \
    --move-call 0x30a8e86de188c74a56495d19d0667a488289bb2a9a7c4ead7b046728ede3553e::nft_marketplace::place_listing \
    "<0xe9b7fce91c894bd228f8128cf14d55dbe7c7ee6c7d94435ff7a5233307c0088d::nft_marketplace::TestnetNFT>" \
    marketplace \
    nft \
    price \
    --gas-budget 20000000
```
