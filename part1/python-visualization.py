# -*- coding: utf-8 -*-
"""
Created on Wed Aug 26 16:54:23 2020

@author: indyp
"""


import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

np.random.seed(0)

mu = 200
sigma = 25
x = np.random.normal(mu, sigma, size=100)

fig, (ax0, ax1) = plt.subplots(ncols=2, figsize=(8, 4))

ax0.hist(x, 20, density=1, histtype='stepfilled', facecolor='g', alpha=0.75)
ax0.set_title('stepfilled')

# Create a histogram by providing the bin edges (unequally spaced).
bins = [100, 150, 180, 195, 205, 220, 250, 300]
ax1.hist(x, bins, density=1, histtype='bar', rwidth=0.8)
ax1.set_title('unequal bins')
fig.tight_layout()
plt.show()




dd = pd.DataFrame(np.random.randn(10, 10)).applymap(abs)
dd = dd.cumsum()

plt.figure()
dd.plot.bar(colormap='Greens')
plt.show()



sns.set(style="whitegrid", palette="muted")

# Load the example iris dataset
iris = sns.load_dataset("iris")

# "Melt" the dataset to "long-form" or "tidy" representation
iris = pd.melt(iris, "species", var_name="measurement")
plt.figure()

# Draw a categorical scatterplot to show each observation
sns.swarmplot(x="measurement", y="value", hue="species", palette=["r", "c", "y"], data=iris)
plt.show()