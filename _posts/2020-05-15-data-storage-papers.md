---
layout: post
type: posts
title: Data Storage Papers that shed light and expand knowledge
date: '2020-05-15T19:50:00.000+01:00'
author: Raul Pingarron
tags:
- Data Storage
---
There have been so many advances in the data storage industry in recent years that anyone with a few decades of experience in the field has witnessed some major paradigm shifts.  In this post I wanted to compile some of the papers related to data storage technology published by **NetApp**, the company I work for a while, since I believe it has been a pioneer in the industry and has contributed and continues to do so with many important breakthroughs.  
I hope that this collection will provide the necessary details to the avid reader who seeks to expand his or her knowledge. Enjoy! :wink:   
   
<p align="center">
  <img width="480" height="300" src="/images/posts/HDD_mdes.jpg">
</p>
   
   

### *File System Design for an NFS File Server Appliance*   
**A must read!**   
This paper \[[^fn1]\] describes the WAFL (Write Anywhere File Layout) file system. The primary focus is on the algorithms and data structures that WAFL uses to implement Snapshots, which are read-only clones of the active file system. This paper also describes how WAFL uses Snapshots to eliminate the need for file system consistency checking after an unclean shutdown.      
A local copy of this paper is also avaiable to <a href="/resources/posts/File_System_Design_for_an_NFS_File_Server_Appliance.pdf" target="_blank">download</a> from my repository.


[^fn1]: Hitz, Dave, James Lau and Michael A. Malcolm. “<a href="https://www.cs.princeton.edu/courses/archive/fall04/cos318/docs/netapp.pdf" target="_blank">*File System Design for an NFS File Server Appliance*.</a>” USENIX Winter (1994).   

* * *  

### *Logical vs. physical file system backup*   
This paper \[[^fn2]\] introduces WAFL, the Consistency Point mechanism and the Snapshot facility and compares logical and physical backup strategies in large file systems.    

[^fn2]: Hutchinson, Norman C., Stephen Manley, Mike Federwisch, Guy Harris, Dave Hitz, Steve R. Kleiman and Sean W. O'Malley. “<a href="https://www.usenix.org/legacy/events/osdi99/full_papers/hutchinson/hutchinson.pdf" target="_blank">*Logical vs. physical file system backup*.</a>” OSDI '99 (1999).   

* * *   

### *Efficient Search for Free Blocks in the WAFL File System*   
The WAFL® write allocator is responsible for assigning blocks on persistent storage to data in a way that maximizes both write throughput to the storage media and subsequent read performance of data.   
This paper \[[^fn3]\] presents and evaluates the techniques used by the WAFL write allocator to quickly and efficiently find regions of free space to achieve its goal.     

[^fn3]: Kesavan, Ram, Matthew Curtis-Maury and Mrinal K. Bhattacharjee. “<a href="https://dl.acm.org/doi/pdf/10.1145/3225058.3225072" target="_blank">*Efficient Search for Free Blocks in the WAFL File System*.</a>” Proceedings of the 47th International Conference on Parallel Processing (2018). Association for Computing Machinery, New York, NY, USA, Article 86, 1–10.       

* * *   

### *Improving block sharing in the Write Anywhere File Layout file system*   
Block sharing is used to improve storage utilization by storing only one copy of a block shared by multiple files or volumes. This thesis \[[^fn4]\] proposes an approach, called Space Maker, which was developed on top of the WAFL file system used in NetApp hardware. The Space Maker is shown to have fast scan performance, while decreasing the front-end time to delete files. Other operations, like file creates and writes have similar performance to a baseline system. Under Space Maker, block sharing is simplified, making a possible for new file system features that rely on sharing to be implemented more quickly with good performance.     

[^fn4]: Grusecki, Travis. “<a href="http://dspace.mit.edu/bitstream/handle/1721.1/76818/825763814-MIT.pdf" target="_blank">*Improving block sharing in the Write Anywhere File Layout file system*.</a>” (2012). Dspace.MIT.edu    

* * *  
   
### *Tracking Back References in a Write-Anywhere File System*   
Back references are file system metadata that map physical block numbers to the data objects that use them. Maintaining back reference metadata with minimal overhead while providing excellent query performance is critical for modern and large-scale storage filesystems that have advanced data management features such as snapshots, writable clones, deduplication, data migration, etc.
This paper [[^fn5]\] introduces Backlog, an efficient implementation of explicit back references, to address this problem.   

[^fn5]: Macko, Peter, Margo I. Seltzer and Keith A. Smith. “<a href="https://pdfs.semanticscholar.org/ed64/763dccde3352a6c6ca86308dc786717211a6.pdf" target="_blank">*Tracking Back References in a Write-Anywhere File System*.</a>” FAST (2010).   

* * *  

### *Efficient Free Space Reclamation in WAFL*   
NetApp®WAFL® is a transactional file system that supports fast write performance and efficient snapshot creation. However, its design increases the demand to find free blocks quickly, which makes rapid free space reclamation essential. Efficiency is also important, because the task of reclaiming free space may consume CPU and other resources at the expense of client operations.   
This article [[^fn6]\] describes the evolution (over more than a decade) of the WAFL algorithms and data structures for reclaiming space with minimal impact to the overall performance of the storage appliance.   

[^fn6]: Kesavan, Ram, Rohit Singh, Travis Grusecki and Yuvraj Patel. “<a href="https://dl.acm.org/doi/pdf/10.1145/3125647" target="_blank">*Efficient Free Space Reclamation in WAFL*.</a>” ACM Transactions on Storage (TOS) 13 (2017).   

* * * 

### *Scalable Write Allocation in the WAFL File System*   
This paper [[^fn7]\] describes the new write allocation architecture for the WAFL file system that scales performance on many cores. It also places the new architecture in the context of the historical parallelization of WAFL and discusses the architectural decisions that have facilitated this parallelism. The resulting system demonstrates increased scalability that results in throughput gains of up to 274% on a multi-core storage system.   

[^fn7]: Curtis-Maury, Matthew, Ram Kesavan and Mrinal K. Bhattacharjee. “<a href="https://atg.netapp.com/wp-content/uploads/2017/08/sw-WAFL.pdf" target="_blank">*Scalable Write Allocation in the WAFL File System*.</a>” 2017 46th International Conference on Parallel Processing (ICPP) (2017): 261-270.  

* * * 

### *Row-Diagonal Parity for Double Disk Failure Correction*   
**A must read!**  
This paper [[^fn8]\] describes the Row-Diagonal Parity algorithm (aka RAID-DP) that was first implemented in Data ONTAP version 6.5.
Row-Diagonal Parity (RDP) protects against double disk failures storing all data unencoded and using only exclusive-or operations to compute parity. RDP is provably optimal in computational complexity, both during construction and reconstruction and like other algorithms, it is optimal in the amount of redundant information stored and accessed. With RDP it is possible to add disks to an existing array without recalculating parity or moving data. Implementation results show that RDP performance can be made nearly equal to single parity RAID-4 and RAID-5 performance.     

[^fn8]: Corbett, Peter F., Robert English, Atul Goel, Tomislav Grcanac, Steve R. Kleiman, James Leong and Sunitha Sankar. “<a href="https://www.usenix.org/legacy/events/fast04/tech/corbett/corbett.pdf" target="_blank">*Row-Diagonal Parity for Double Disk Failure Correction (Awarded Best Paper!)*.</a>” FAST (2004).    

* * * 

### *FlexVol: Flexible, Efficient File Volume Virtualization in WAFL*   
NetApp's FlexVols added a new level of indirection between client-visible volumes and the underlying physical storage. The resulting virtual file volumes, or FlexVol® volumes, are managed independent of lower storage layers. Multiple volumes can be dynamically created, deleted, resized, and reconfigured within the same physical storage container.   
This paper [[^fn9]\] presents the basic architecture of FlexVol volumes, including performance optimizations that decrease the overhead of this new virtualization layer.   
A local copy of this paper is also avaiable to <a href="/resources/posts/FlexVol_Flexible+Efficient_File_Volume_Virtualization_in_WAFL.pdf" target="_blank">download</a> from my repository.

[^fn9]: Edwards, J.K., Ellard, D., Everhart, C., Fair, R., Hamilton, E., Kahn, A., Kanevsky, A., Lentini, J., Prakash, A., Smith, K.A., & Zayas, E.R. "<a href="https://pdfs.semanticscholar.org/7062/268b78dff4a8819fe3f1e89c6b5344f715a5.pdf" target="_blank">*FlexVol: Flexible, Efficient File Volume Virtualization in WAFL*</a>". USENIX Annual Technical Conference (2008).   

* * *   

### *SnapMirror: File-System-Based Asynchronous Mirroring for Disaster Recovery*   
This paper [[^fn10]\] presents SnapMirror, an asynchronous mirroring technology that leverages file system snapshots to ensure the consistency of the remote mirror and optimize data transfer. Traces of production systems are used to show that even updating an asynchronous mirror every 15 minutes can reduce data transferred by 30% to 80%. Experiments on a running system show that using file system metadata can reduce the time to identify changed blocks from minutes to seconds compared to purely logical approaches. Finally, the paper shows that using SnapMirror to update every 30 minutes increases the response time of a heavily loaded system only 22%.   


[^fn10]: Patterson, R. Hugo, Stephen Manley, Mike Federwisch, Dave Hitz, Steve R. Kleiman and Shane Owara. “<a href="https://pdfs.semanticscholar.org/7062/268b78dff4a8819fe3f1e89c6b5344f715a5.pdf" target="_blank">*SnapMirror: File-System-Based Asynchronous Mirroring for Disaster Recovery*.</a>” FAST (2002).    

* * *   

### *Hybrid aggregates: combining SSDs and HDDs in a single storage pool*   
This paper [[^fn11]\] describes the implementation of the Hybrid Aggregates prototype back in 2008 and the policies for automatic data placement and movement that were  evaluated. One of the primary goals of the project was to determine whether a hybrid aggregate, composed of SSDs and Serial-ATA (SATA) disks, could simultaneously provide better cost/performance and cost/throughput ratios than an all Fibre-Channel (FC) solution.
The project took a two-pronged approach to building a prototype system capable of supporting hybrid aggregates. The first part of the project investigated the changes necessary for Data ONTAP RAID and WAFL® layers to support a hybrid aggregate. This included propagating disk-type information to WAFL, modifying WAFL to support the allocation of blocks from a particular storage class (i.e., disk type), and repurposing the existing infrastructure to support the movement of data between storage classes. The second part of the project examined potential policies for allocating and moving data between storage classes within a hybrid aggregate. Through proper policies, it is possible to automatically segregate the data within the aggregate such that the SSD-backed portion of the aggregate absorbs a large fraction of the I/O requests, leaving the SATA disks to contribute capacity for colder data.   


[^fn11]: Strunk, John D.. “<a href="http://web.cse.ohio-state.edu/~zhang.574/NetApp-hAggregates-2012.pdf" target="_blank">*Hybrid aggregates: combining SSDs and HDDs in a single storage pool*.</a>” Operating Systems Review 46 (2012).
   
* * *  

### *Storage Gardening: Using a Virtualization Layer for Efficient Defragmentation in the WAFL File System*   
This paper [[^fn12]\] presents the techniques that efficiently address each form of fragmentation in the WAFL file system, which are referred 
to collectively as storage gardening. These techniques are novel because they leverage WAFL’s implementation of virtualized file system instances (FlexVol® volumes) to efficiently relocate data physically while updating a minimal amount of metadata, unlike other file systems and defragmentation tools.  


[^fn12]: Kesavan, Ram, Matthew Curtis-Maury, Vinay Devadas and Kesari Mishra. “<a href="http://pdfs.semanticscholar.org/4119/cd1d35c2ae84a56d5c1b01af9ec7f0989746.pdf" target="_blank">*Storage Gardening: Using a Virtualization Layer for Efficient Defragmentation in the WAFL File System*.</a>” FAST (2019).   

* * *  

### *Countering Fragmentation in an Enterprise Storage System*   
This article [[^fn13]\] studies each form of fragmentation in the NetApp® WAFL®file system, and explains how the file system leverages a storage virtualization layer for defragmentation techniques that physically relocate blocks efficiently, including those in read-only snapshots. The article analyzes the effectiveness of these techniques at reducing fragmentation and improving overall performance across various storage media. 


[^fn13]: Kesavan, Ram, Matthew Curtis-Maury, Vinay Devadas and Kesari Mishra. “<a href="https://dl.acm.org/doi/pdf/10.1145/3366173?download=true" target="_blank">*Countering Fragmentation in an Enterprise Storage System*.</a>” ACM Transactions on Storage (TOS) 15 (2020).   

* * *  


### *All-Flash FAS: A Deep Dive*   
Despite NetApp has been shipping all-flash FAS configurations for a number of years, this article [[^fn14]\] introduces the All-Flash DAS systems  and also discusses why Data ONTAP's Write Anywhere File Layout (WAFL) is ideal for all-flash environments.   
A PDF copy of this article is also avaiable to <a href="/resources/posts/All-Flash%20FAS-%20A%20Deep%20Dive.pdf" target="_blank">download</a> from my repository.

[^fn14]: Saurabh Modh, Chetan Khetani. “<a href="https://community.netapp.com/t5/Tech-OnTap-Articles/All-Flash-FAS-A-Deep-Dive/ta-p/87211" target="_blank">*All-Flash FAS: A Deep Dive*.</a>” Tech OnTap Articles (2014).   

* * *  