# Simultaneous dPul-PPC Neural Recording Analysis Toolbox

## Overview
This MATLAB toolbox processes and analyzes neural recordings from experiments studying interactions between the dorsal pulvinar (dPul) and posterior parietal cortex (PPC, specifically LIP - Lateral Intraparietal area).

## Experimental Structure

### Three Types of Sessions:
1. **Experiment 1** (`injection == '2'`)
   - Studies functional interactions between dPul and LIP during spatial target selection
   - Regular recording sessions without injections
   - Subjects:
     - Linus: 8 sessions (Nov 2021)
     - Bacchus: 9 sessions (Mar-Jun 2020)

2. **Experiment 2** (`injection == '1'`)
   - Studies unilateral dPul inactivation effects on LIP activity
   - Injection sessions:
     - Linus: 
       - Right dPul: 7 sessions
       - Left dPul: 3 sessions
     - Bacchus:
       - Right dPul only: 7 sessions

3. **Control Sessions** (`injection == '0'`)
   - Baseline recordings without injections
   - Linus: 8 sessions
   - Bacchus: 7 sessions

## Data Flow Architecture

### 1. Session Management
- **Entry Point**: `filelist_of_days_from_Simultaneous_dPul_PPC_recordings.m`
  - Manages recording session dates
  - Parameters:
    - `monkey`: Subject identifier ('Linus' or 'Bacchus')
    - `injection`: Session type ('0', '1', or '2')
    - `typeOfSessions`: Injection site ('right', 'left', 'all', or ' ')

### 2. Configuration
- **Settings**: `sdndt_Sim_LIP_dPul_NDT_settings.m`
  - Defines paths and parameters
  - Sets up output directories for:
    - Raw data
    - Raster data
    - Binned data

### 3. Data Processing Pipeline

#### a. File Management
- `sdndt_Sim_LIP_dPul_NDT_make_list_of_required_files.m`
  - Creates lists of required files for processing
  - Handles both individual sessions and merged files

#### b. Raw Data Processing
- `sdndt_Sim_LIP_dPul_NDT_make_raster.m`
  - Converts raw recordings to raster format
  - Creates binary spike matrices

#### c. Analysis Components
- **Spiking Activity Analysis**:
  - `sdndt_Sim_LIP_dPul_NDT_spiking_activity.m`
  - `sdndt_Sim_LIP_dPul_NDT_spiking_activity_conv.m` (with convolution)
  
- **Neural Decoding**:
  - `sdndt_Sim_LIP_dPul_NDT_decoding.m`
  - Cross-decoding capabilities via `sdndt_Sim_LIP_dPul_NDT_cross_decoding.m`

#### d. Visualization
- `sdndt_Sim_LIP_dPul_NDT_plot_raster.m`
  - Generates raster plots
  - Visualizes neural activity patterns

#### e. Statistical Analysis
- `sdndt_Sim_LIP_dPul_NDT_statistics.m`
  - Performs statistical analyses
  - Handles both individual and merged sessions

### 4. Results Processing
- Averaging functions for:
  - Individual sessions
  - Cross-decoding results
  - Population analyses

## File Organization

plaintext
├── Raw Data
│ └── Simultaneous_dPul_PPC_recordings/ephys/
├── Processed Data
│ ├── raster/
│ │ ├── right_dPul_injection/
│ │ ├── left_dPul_injection/
│ │ └── both_R_and_L_dPul_injection/
│ └── binned/
└── Analysis Results

## Usage Flow

1. **Setup**:
   - Configure settings via `sdndt_Sim_LIP_dPul_NDT_settings`
   - Select session dates using `filelist_of_days_from_Simultaneous_dPul_PPC_recordings`

2. **Data Processing**:
   - Generate file lists
   - Create raster data
   - Apply convolution if needed

3. **Analysis**:
   - Run spiking activity analysis
   - Perform neural decoding
   - Execute statistical tests

4. **Visualization**:
   - Generate raster plots
   - Create summary visualizations

## Dependencies
- MATLAB (version requirements not specified)
- Neural Decoding Toolbox (NDT) integration
