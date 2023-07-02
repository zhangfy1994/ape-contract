## 此项目主要参考`@openzeppelin/contracts` 和 `BAYC无聊猿` 源码实现。

### 部署到`Polygon Mumbai 测试网络`

### [前端项目地址](https://github.com/zhangfy1994/ape-app)

## 项目目录

- `contracts` 是合约文件。

- `test` 目录是测试文件

- `scripts` 目录是部署文件

## 主要技术

- `solidity^0.8.0`
- `hardhat` 开发环境
- `chai`、`hardhat-ethers` 测试
- `thirdweb` 构建、部署合约
- `pnpm` 管理依赖

## ⚠️ 注意点

- node 版本要 `>=18`，是 hardhat 的测试插件要求

## 项目使用

- 安装依赖

```shell
npm install

pnpm install

yarn install
```

- 跑测试

```shell
npx hardhat test

// 或指定具体测试文件
npx hardhat test ./test/filename
```

- 部署

```shell
// 通过thirdweb dsahboard 部署
// https://portal.thirdweb.com/getting-started/contracts
pnpm run deploy

// 部署到本地环境
npx hardhat run scripts/deploy.ts --network localhost
```
