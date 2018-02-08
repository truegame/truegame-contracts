export interface NetworkParams {
    id: number;
    name: string;
    genesisAddress?: string;
}

export let networks: NetworkParams[] = [
    {
        id: 314,
        name: 'TestRPC',
        genesisAddress: undefined
    }
];

