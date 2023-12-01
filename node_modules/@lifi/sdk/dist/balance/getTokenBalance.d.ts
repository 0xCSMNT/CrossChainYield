import { Token, TokenAmount } from '@lifi/types';
export declare const getTokenBalance: (walletAddress: string, token: Token) => Promise<TokenAmount | null>;
export declare const getTokenBalances: (walletAddress: string, tokens: Token[]) => Promise<TokenAmount[]>;
export declare const getTokenBalancesForChains: (walletAddress: string, tokensByChain: {
    [chainId: number]: Token[];
}) => Promise<{
    [chainId: number]: TokenAmount[];
}>;
