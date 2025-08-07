module vai::NFTBreeding {
    use aptos_framework::signer;
    use std::vector;
    use aptos_framework::timestamp;
    
    /// Struct representing an NFT with genetic traits
    struct NFT has store, key, copy, drop {
        id: u64,
        dna: vector<u8>,     // Genetic code represented as bytes
        generation: u64,     // Which generation this NFT belongs to
        birth_time: u64,     // When this NFT was created/bred
    }
    
    /// Struct to store user's NFT collection
    struct NFTCollection has key {
        nfts: vector<NFT>,
        next_id: u64,
    }
    
    /// Function to mint an initial NFT with random genetic traits
    public fun mint_genesis_nft (owner: &signer, dna: vector<u8>) acquires NFTCollection {
        let nft = NFT {
            id: 1,
            dna,
            generation: 0,
            birth_time: timestamp::now_seconds(),
        };
        
        if (!exists<NFTCollection>(signer::address_of(owner))) {
            let collection = NFTCollection {
                nfts: vector::empty<NFT>(),
                next_id: 2,
            };
            move_to(owner, collection);
        };
        
        let collection = borrow_global_mut<NFTCollection>(signer::address_of(owner));
        vector::push_back(&mut collection.nfts, nft);
    }
    
    /// Function to breed two NFTs and create offspring with combined genetics
    public fun breed_nfts(owner: &signer, parent1_id: u64, parent2_id: u64) acquires NFTCollection {
        let collection = borrow_global_mut<NFTCollection>(signer::address_of(owner));
        let parent1_dna = vector::empty<u8>();
        let parent2_dna = vector::empty<u8>();
        let max_generation = 0;
        
        // Find parent NFTs and get their DNA
        let i = 0;
        while (i < vector::length(&collection.nfts)) {
            let nft = vector::borrow(&collection.nfts, i);
            if (nft.id == parent1_id) {
                parent1_dna = nft.dna;
                if (nft.generation > max_generation) max_generation = nft.generation;
            };
            if (nft.id == parent2_id) {
                parent2_dna = nft.dna;
                if (nft.generation > max_generation) max_generation = nft.generation;
            };
            i = i + 1;
        };
        
        // Simple genetic algorithm: combine DNA from both parents
        let child_dna = vector::empty<u8>();
        let dna_len = if (vector::length(&parent1_dna) < vector::length(&parent2_dna)) {
            vector::length(&parent1_dna)
        } else {
            vector::length(&parent2_dna)
        };
        
        let j = 0;
        while (j < dna_len) {
            let gene = if (j % 2 == 0) {
                *vector::borrow(&parent1_dna, j)
            } else {
                *vector::borrow(&parent2_dna, j)
            };
            vector::push_back(&mut child_dna, gene);
            j = j + 1;
        };
        
        // Create the bred NFT
        let child = NFT {
            id: collection.next_id,
            dna: child_dna,
            generation: max_generation + 1,
            birth_time: timestamp::now_seconds(),
        };
        
        vector::push_back(&mut collection.nfts, child);
        collection.next_id = collection.next_id + 1;
    }
}