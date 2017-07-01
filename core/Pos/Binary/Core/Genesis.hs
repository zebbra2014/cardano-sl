-- | Binary instances for Genesis data (such as `StakeDistribution`)

module Pos.Binary.Core.Genesis () where

import           Universum

import           Pos.Binary.Class        (Bi (..), Cons (..), Field (..), Peek,
                                          PokeWithSize, UnsignedVarInt (..),
                                          convertToSizeNPut, deriveSimpleBi, getWord8,
                                          label, labelS, putField, putS, putWord8S)
import           Pos.Binary.Core.Address ()
import           Pos.Binary.Core.Types   ()
import           Pos.Core.Address        ()
import           Pos.Core.Genesis.Types  (GenesisCoreData (..), GenesisCoreData0 (..),
                                          StakeDistribution (..), mkGenesisCoreData)
import           Pos.Core.Types          (Address, Coin, StakeholderId)

getUVI :: Peek Word
getUVI = getUnsignedVarInt <$> get

putUVI :: Word -> PokeWithSize ()
putUVI = putS . UnsignedVarInt

instance Bi StakeDistribution where
    get = label "StakeDistribution" $ getWord8 >>= \case
        0 -> FlatStakes <$> getUVI <*> get
        1 -> BitcoinStakes <$> getUVI <*> get
        2 -> RichPoorStakes <$> getUVI <*> get <*> getUVI <*> get
        3 -> pure ExponentialStakes
        4 -> CustomStakes <$> get
        _ -> fail "Pos.Binary.Genesis: StakeDistribution: invalid tag"
    sizeNPut = labelS "StakeDistribution" $ convertToSizeNPut f
      where
        f :: StakeDistribution -> PokeWithSize ()
        f (FlatStakes n total)       = putWord8S 0 <> putUVI n <> putS total
        f (BitcoinStakes n total)    = putWord8S 1 <> putUVI n <> putS total
        f (RichPoorStakes m rs n ps) =
            putWord8S 2 <> putUVI m <> putS rs <>
            putUVI n <> putS ps
        f ExponentialStakes          = putWord8S 3
        f (CustomStakes coins)       = putWord8S 4 <> putS coins

instance Bi GenesisCoreData where
    get = label "GenesisCoreData" $ do
        addrDistribution <- get
        bootstrapStakeholders <- get
        case mkGenesisCoreData addrDistribution bootstrapStakeholders of
            Left e  -> fail $ "Couldn't construct genesis data: " <> e
            Right x -> pure x
    sizeNPut =
        labelS "GenesisCoreData" $
            putField gcdAddrDistribution <>
            putField gcdBootstrapStakeholders

-- compatibility
deriveSimpleBi ''GenesisCoreData0 [
    Cons 'GenesisCoreData0 [
        Field [| _0gcdAddresses         :: [Address]                  |],
        Field [| _0gcdDistribution      :: StakeDistribution          |],
        Field [| _0gcdBootstrapBalances :: HashMap StakeholderId Coin |]
    ]]
