import { LifiErrorCode, ProviderError } from './errors';
export const getProvider = (signer) => {
    if (!signer.provider) {
        throw new ProviderError(LifiErrorCode.ProviderUnavailable, 'No provider available in signer.');
    }
    return signer.provider;
};
