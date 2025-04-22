interface SettingsService {
    current: Settings;
    file: string;
}

interface Settings {
    cache_dir: string;
    icons: {
        danger: {
            icon: string;
            color: string;
        }
    };
    workspaces: {
        [key: number]: {
            icon: string;
            colors: {
                inactive: string;
                active: string;
                monitor0: string;
                monitor1: string;
                monitor2: string;
                monitor3: string;
            }
        }
    }
}

class Settings extends Service implements SettingsService {
    file = `${App.configDir}/default-settings.json`;
    #current = JSON.parse(Utils.readFile(`${this.file}`));
    
    static {
        Service.register(
            this,
            {
                'workspace-change': ["jsobject"],
            },
            {
                'current': ["jsobject", 'r'],
            },
        );
    }

    // the getter has to be in snake_case
    get current() {
        return this.#current;
    }

    getWorkspace(id:number) {
        return this.#current?.workspaces[id]
    }

    constructor() {
        super();

        // setup monitor
        Utils.monitorFile(this.file, () => this.#onChange());

        // initialize
        this.#onChange();
    }
    
    // Compares 2 objects and returns diff
    #getANewOneIfPropChanged(oldOne, newOne) {
        for (let prop in oldOne) {
            if (oldOne[prop] !== newOne[prop]) {
                return newOne;
            }
        }
        return oldOne;
    }

    #onChange() {
        const oldSettings = this.#current;
        this.#current = JSON.parse(Utils.readFile(this.file));

        // Emits changed, and notifies the listeners of 'settings'
        this.changed('current');

        // Check if something on the workspaces has changed
        if (oldSettings.workspaces !== this.#current) {
            console.log(oldSettings.workspaces[1], this.#current.workspaces[1]);
            console.log(this.#getANewOneIfPropChanged(this.#current.workspaces, oldSettings.workspaces));
            // this.emit('workspace-change', this.#current);
        }
        // emit workspace-change with the percent as a parameter
        this.emit('workspace-change', this.#current);
    }

    connect(event = 'change', callback) {
        return super.connect(event, callback);
    }
}

// the singleton instance
const service = new Settings;

// export to use in other modules
export default service;