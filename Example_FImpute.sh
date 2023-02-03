#!/bin/bash

# ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~
#time requirement recommended -l h_rt=05:00:00
# memory requirement --> recommended -l h_vmem=28G


# ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~  Script to PREPARE INPUT FILES and RUN IMPUTATION using FImpute3 software  # ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ 

### Format of INPUT files
# genotype_file (WITH HEADER): IID(max 30 characters), Chip_number, genotype calls (0,1,2,5)  
# snp_info_file (WITH HEADER): SNP_ID(max 50 characters), chromosome, position(bp), order of SNP for each chip --> one column per Chip and maximum of 10 chips
# pedigree_file: IndividualID, SireID, DamID, sex(F/M/U) --> if not defined the family-based imputation is automatically turned off
## IN this script the HD is Chip 1 and the LD is Chip 2


##### SET UP names of files and directories 
User=<user_name>
MyProject=<project_name>
MyData=<Data_name>

# NAME and LOCATION of the LD_panel to impute. This data has to be in PLINK BINARY FORMAT and PLINK .raw format
LD_data=<path_LD_data/Name_LD_data>
# NAME and LOCATION of the HD_panel used as reference. This data has to be in PLINK BINARY FORMAT and PLINK .raw format
HD_data=<path_HD_data/Name_HD_data>
# pedigree_file: IndividualID, SireID, DamID, sex(F/M/U) --> if not defined the family-based imputation is automatically turned off
Pedigree_data=<Your pedigree file>

workDR=<path to your working directory>
cd ${workDR}


#### Step 1: We create the map file for the HD and LD genotypes, CHIP=1 for HD and CHIP=2 for LD 
# INPUT: plink .raw file 
# OUTPUT: .map file with HEADER <SNP_ID  CHR   POS(bp)   CHIPpos>

gawk -F' ' '{print $2 "\t" $1 "\t" $4 "\t" NR}' ${HD_data}.bim > ${MyData}_HD.map

gawk -F' ' '{print $2 "\t" $1 "\t" $4 "\t" NR}' ${LD_data}.bim > ${MyData}_LD.map


#### Step 2: We create the genotype file for the HD genotypes 
# INPUT: plink .raw file 
# OUTPUT: . geno file < IID		CHIP	Call...................... >(HEADER and Tab separated file)
# 	eg.	                SNP1	1		012221200521012 ## genotypes calls = 0125 NO SPACES
#   eg. 				SNP2    1		012012550120125 

#From the .raw file we remove the FID($1) the SID, DID, Sex and Phenotype ($3 to $6)

#We change the NA into 5 for missing genotype value
gawk 'NR!=1 {$1="";$3="";$4="";$5="";$6="";$2=$2";"; gsub(/ /,""); gsub(/NA/,5); print $0}' ${HD_data}.raw > temp_HD.geno
gawk '(NR!=1){$1="";$3="";$4="";$5="";$6="";$2=$2";";gsub(/NA/,5); gsub(/ /,""); print $0}' ${LD_data}.raw > temp_LD.geno

#We add the header and the CHIP number
gawk -F';' 'BEGIN {print "IID" "\t" "Chip" "\t" "Call..........."}  {print $1 "\t" 1 "\t" $2}' temp_HD.geno > ${MyData}_HD.geno
gawk -F';' 'BEGIN {print "IID" "\t" "Chip" "\t" "Call..........."}  {print $1 "\t" 2 "\t" $2}' temp_LD.geno > ${MyData}_LD.geno

#We delete temporary files
rm temp_HD.geno
rm temp_LD.geno


#### Step 3: We combine the information for the two chips (HD and LD)

gawk ' BEGIN { FILE1= ARGV[1] ; FILE2= ARGV[2];  {print "SNP_ID" "\t" "Chr" "\t" "Pos" "\t" "Chip1=HD" "\t" "Chip2=LD"} }
		   { if (FILENAME == FILE1) { ID[$1]= $1 ; ORD[$1]=$4 } 
			 if (FILENAME == FILE2) { if (ID[$1]!="") {irc= ID[$1] ; rang=ORD[$1] ; $1="\t"; print irc $0 "\t" rang } 
									  else {rang=0 ; print $0 "\t" rang }}}' ${MyData}_LD.map ${MyData}_HD.map > ${MyData}_Combined.map
									  
				  

#### run IMPUTATION
#create OUTPUT directory 
mkdir ${MyData}_Output

# For more options from  see FImpute3 documentation
# options:
# save_genotype : save genotype instead of haplotypes (0 1 2 5) format
# njob = nb of jobs to be run in parallel
# parentage_test /off : skip parentage test
# keep_og = prevents change in original genotypes during imputation process
# ref_chip = Specify reference chip for imputation (i.e. high density chip)
# -o = 

cat > ${MyData}_FImpute_param.ctr <<EOF
 title="Imputation of ${MyProject}";
 genotype_file="${MyData}_LD.geno" "${MyData}_HD.geno";
 snp_info_file="${MyData}_Combined.map";
 output_folder="${MyData}_Output";
 ped_file="${Pedigree_data.ped}";
 keep_og;
 save_genotype;
 ref_chip=1; 
 parentage_test /ert_mm=0.05 /find_match_cnflt;
 njob=10;
EOF
 
FImpute3 ${MyData}_FImpute_param.ctr -o




# ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~ ~~~~ ><(((^> ~~~~~
