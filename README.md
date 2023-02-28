# Mr Steal Yo Crypto - Foundry Version ⚒️

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/vyorkin/mr-steal-your-crypto-ctf-foundry)

Visit [mrstealyocrypto.xyz](https://mrstealyocrypto.xyz/)

### Acknowledgements

- _Big thanks to [0xToshii](https://twitter.com/0xToshii) who created the [original version of this game](https://github.com/0xToshii/mr-steal-yo-crypto-ctf) and to all the fellows behind the [Foundry Framework](https://github.com/0xToshii/mr-steal-yo-crypto-ctf)_
- _Thanks to [Nicolás García](https://twitter.com/ngp2311) who created the [foundry version of Damn Vulnerable DeFi](https://github.com/nicolasgarcia214/damn-vulnerable-defi-foundry) which is used as a basis for this repo_

Mr Steal Yo Crypto is a series of wargame challenges where you are tasked with exploiting smart contracts covering varying use cases within crypto.
The challenges are loosely (or directly) inspired by real world exploits. Throughout numerous challenges you will build the skills necessary to become a hunter in the space.

## How To Play 🕹️

1.  **Install Foundry**

First run the command below to get foundryup, the Foundry toolchain installer:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

Then, in a new terminal session or after reloading your PATH, run it to get the latest forge and cast binaries:

```console
foundryup
```

Advanced ways to use `foundryup`, and other documentation, can be found in the [foundryup package](./foundryup/README.md)

2. **Clone This Repo and install dependencies**

```
git clone https://github.com/vyorkin/mr-steal-your-crypto-ctf-foundry.git
cd mr-steal-your-crypto-ctf-foundry
forge install
```

3. **Code your solutions in the provided `[NAME_OF_THE_LEVEL].t.sol` files (inside each level's folder in the test folder)**
4. **Run your exploit for a challenge**

```
make [CONTRACT_LEVEL_NAME]
```

or

```
./run.sh [LEVEL_FOLDER_NAME]
./run.sh [CHALLENGE_NUMBER]
./run.sh [4_FIRST_LETTER_OF_NAME]
```

If the challenge is executed successfully, you've passed!🙌🙌

### Tips and tricks ✨

- In all challenges you must use the account called attacker. In Forge, you can use the [cheat code](https://github.com/gakonst/foundry/tree/master/forge#cheat-codes) `prank` or `startPrank`.
- To code the solutions, you may need to refer to [Forge docs](https://onbjerg.github.io/foundry-book/forge/index.html).
- In some cases, you may need to code and deploy custom smart contracts.
