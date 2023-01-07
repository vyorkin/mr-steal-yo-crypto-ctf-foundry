.PHONY: JpegSniper
JpegSniper:
	forge test -vvv --match-test testExploit --match-contract FlatLaunchpegTest

.PHONY: SafuVault
SafuVault:
	forge test -vvv --match-test testExploit --match-contract SafuVaultTest

.PHONY: GameAssets
GameAssets:
	forge test -vvv --match-test testExploit --match-contract GameAssetsTest

.PHONY: FreeLunch
FreeLunch:
	forge test -vvv --match-test testExploit --match-contract SafuMakerV2Test
