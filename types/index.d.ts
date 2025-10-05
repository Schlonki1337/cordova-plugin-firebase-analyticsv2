interface CordovaPlugins {
    firebase: FirebasePlugins;
}

interface FirebasePlugins {
    analytics: typeof import("./FirebaseAnalytics");
}

export interface IChannelOptions {
    id: string
    name?: string
    description?: string
    sound?: string
    vibration?: boolean | number[]
    light?: boolean
    lightColor?: string
    importance?: 0 | 1 | 2 | 3 | 4
    badge?: boolean
    visibility?: -1 | 0 | 1
    usage?: number
    streamType?: number
}
