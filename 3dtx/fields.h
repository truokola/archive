struct bnode {
    int i, j;
    double seglen;
    double normx, normy;
    double w1, w2, w3, w4;
    struct bnode *next;
};

typedef struct {
    double ***v;
    int nx, ny, nz;
    double aspect;
    double offset;
} sfield;

typedef struct {
    double ***vx, ***vy, ***vz;
    int nx, ny, nz;
    double aspect;
    double offset;
} vfield;

struct geometry {
    int nr;
    double **area;
    int *firstcell;
    int *firstnode;
    int total_nodes;
    struct bnode *boundary;
};



sfield cyl_sfield(int nr, int nz, double aspect);
void kill_sfield(sfield f);

vfield cyl_vfield(int nr, int nz, double aspect);
vfield cyl_nfield(int nr, int nz, double aspect);
void kill_vfield(vfield f);

struct geometry get_disk_geometry(int nr);
void kill_geometry(struct geometry geom);

void dump_sfield(sfield f, char file[]);
void dump_vfield(vfield f, char file[]);

void divergence(vfield f, sfield resf);
void curl(vfield f, vfield resf);

double volume_integral(struct geometry g, sfield f);
