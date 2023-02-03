# Imputation with FImputev3 by Clémence Fraslin
Scripts to prepare and impute genotype from SNP arrays data using FImpute v3 
Here we describe a step-by-step pipeline to create input data and perform genotype imputation of SNP array data using FImpute v3 software. The pipeline uses the input in PLINK files (.raw and .bim) and FImpute v3 software for imputation. FImpute3 is not a publicly available software but there is a free licence for academic. Contact Dr Mehdi Sargolzaei FImpute3 developer to access the license: hgs.msargolzaei@gmail.com

## 1. Create snp_info_file (map) and genotype_file

We create the map file for each density from a .bim file (PLINK format)

INPUT: plink .raw file 

OUTPUT: .map file with HEADER < SNP_ID  CHR   POS(bp)   position_on _chip>

```
gawk -F' ' '{print $2 "\t" $1 "\t" $4 "\t" NR}' HD_data.bim > MyData_HD.map
gawk -F' ' '{print $2 "\t" $1 "\t" $4 "\t" NR}' LD_data.bim > MyData_LD.map
```

### We create the genotype file fo the HD and LD genotypes.

INPUT: plink .raw file 

OUTPUT: .geno file <  IID   CHIP_num  Call...................... > (HEADER and Tab separated file)
eg of the first line: SNP1  1   012012550120125...

From the .raw file we remove the Family ID ($1) the Sir ID, Dam ID, Sex and Phenotype ($3 to $6) and we change the NA into 5 for missing genotype value.
We add the header, the CHIP number and we use a TAB delimitation.
```
gawk 'NR!=1 {$1="";$3="";$4="";$5="";$6="";$2=$2";"; gsub(/ /,""); gsub(/NA/,5); print $0}' HD_data.raw > temp_HD.geno
gawk '(NR!=1){$1="";$3="";$4="";$5="";$6="";$2=$2";";gsub(/NA/,5); gsub(/ /,""); print $0}' LD_data.raw > temp_LD.geno
gawk -F';' 'BEGIN {print "IID" "\t" "Chip" "\t" "Call..........."}  {print $1 "\t" 1 "\t" $2}' temp_HD.geno > MyData_HD.geno
gawk -F';' 'BEGIN {print "IID" "\t" "Chip" "\t" "Call..........."}  {print $1 "\t" 2 "\t" $2}' temp_LD.geno > MyData_LD.geno
```

### We Combined the information for the two chips (HD and LD)

INPUT: map files created previously

OUTPUT: a combined Snp_info_file  < SNP_ID Chromosome Position(bp) Position_on_chip1 Position_on_chip2 > 

This command lines compares the map of the two chips:
- If a SNP is common between the two maps we write the position of the SNP on chip1 in the 4th column and on chip2 in the 5th column of the file.
- If a SNP is present only in the HD-panel (Chip 1) and not the LD_panel (Chip 2) we write the SNP position on the map in the 4th column and we write 0 in the 5th column.

```
gawk ' BEGIN { FILE1= ARGV[1] ; FILE2= ARGV[2];  {print "SNP_ID" "\t" "Chr" "\t" "Pos" "\t" "Chip1=HD" "\t" "Chip2=LD"} }
       { if (FILENAME == FILE1) { ID[$1]= $1 ; ORD[$1]=$4 } 
       if (FILENAME == FILE2) { if (ID[$1]!="") {irc= ID[$1] ; rang=ORD[$1] ; $1="\t"; print irc $0 "\t" rang } 
                    else {rang=0 ; print $0 "\t" rang }}}' MyData_LD.map MyData_HD.map > MyData_Combined.map
```     

## 2. Create the parameter file for FImpute and run it 

 ```
cat > MyData_FImpute_param.ctr <<EOF
 title="Imputation of Project_name";
 genotype_file="MyData_LD.geno" "MyData_HD.geno";
 snp_info_file="MyData_Combined.map";
 output_folder="MyData_Output";
 ped_file="pedigree_file";
 keep_og;
 save_genotype;
 parentage_test  /off;
 ref_chip=1; 
 njob=10;
EOF

FImpute3 ${MyData}_FImpute_param.ctr -o
 ```

For more options from  see FImpute3 documentation
options in this parameter file are :
keep_og = prevents change in original genotypes during imputation process

save_genotype : save genotype instead of haplotypes (0 1 2 5) format

parentage_test /off : skip parentage test 
or 
parentage_test /ert_mm=0.05 = error rate threshold to find progeny-parent mismatches 

ref_chip = Specify reference chip for imputation (i.e. high density chip)

njob = nb of jobs to be run in parallel


