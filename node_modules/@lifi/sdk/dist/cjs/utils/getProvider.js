"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getProvider = void 0;
const errors_1 = require("./errors");
const getProvider = (signer) => {
    if (!signer.provider) {
        throw new errors_1.ProviderError(errors_1.LifiErrorCode.ProviderUnavailable, 'No provider available in signer.');
    }
    return signer.provider;
};
exports.getProvider = getProvider;
