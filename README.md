# DF-PCAP-AI-Detection
Digital Forensics Final Project
1. PCAP Parsing (parse_pcap.py)
Raw .pcap files are read using scapy or pyshark and converted into a CSV where each row is a network flow or packet with features like source/dest IP, port, protocol, packet size, and duration.
2. Feature Engineering (features.py)
The raw CSV gets cleaned and enriched — things like encoding protocols as numbers, calculating flow statistics, and dropping irrelevant columns. Output is a model-ready dataset.
3. ML Model (model.py)
A classifier (Random Forest is a good starting point) is trained on the labeled dataset to predict each flow as normal or malicious. You evaluate with precision, recall, and F1 score since the data will likely be imbalanced.
4. Forensics Validation
The flagged malicious flows get manually inspected in Wireshark to confirm the AI's findings make sense.
